"""Wake proxy: forward LiteLLM's ixian traffic, waking ixian first if it sleeps.

ixian suspends itself when idle (machines/ixian/_suspend.nix). LiteLLM's ixian
backend points here instead of at model-router directly. For each incoming
connection the proxy connects to model-router with a short timeout:

  * reachable: it pipes the bytes both ways, unchanged (a plain TCP proxy, so
    streaming, headers and the backend key pass through as they are);
  * not reachable: it sends a Wake-on-LAN packet (wake-ixian), keeps retrying
    the connection, re-sends the packet every REWAKE seconds, and forwards the
    waiting request once model-router answers. On ixian's side, idle-suspend
    starts Strata after a network wake, and model-router holds requests until
    Strata is ready, so the client simply gets its answer a minute or two late.

If ixian doesn't answer within WAIT seconds the client connection is closed,
and LiteLLM reports the error. There is deliberately no fallback to another
model. While ixian is gaming, model-router answers 503 at once and that 503
is passed through unchanged.

Only inference wakes ixian. LiteLLM asks each ixian model entry for the model
list (GET /v1/models) every 5 minutes, and other clients ask at startup; each
of those woke ixian and started a model load. So the proxy reads the request
line first: a GET for .../models while ixian is unreachable is answered here,
with the models passed as --model, and doesn't wake it. While ixian is awake
everything is forwarded, model lists included.

Only the standard library (asyncio).
"""

import argparse
import asyncio
import json
import sys
import time


def log(message):
    print(message, flush=True)


class WakeProxy:
    def __init__(self, args):
        self.a = args
        self.last_wake = 0.0
        self.wake_lock = asyncio.Lock()

    async def wake(self):
        async with self.wake_lock:
            if time.monotonic() - self.last_wake < self.a.rewake:
                return
            self.last_wake = time.monotonic()
            proc = await asyncio.create_subprocess_exec(
                *self.a.wake_cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT,
            )
            out, _ = await proc.communicate()
            log(f"wake sent ({out.decode().strip() or 'no output'}, exit {proc.returncode})")

    async def connect(self):
        return await asyncio.wait_for(
            asyncio.open_connection(self.a.upstream_host, self.a.upstream_port),
            timeout=self.a.connect_timeout,
        )

    async def connect_waking(self):
        """Connect to model-router, waking ixian and waiting for it if needed."""
        try:
            return await self.connect()
        except (OSError, asyncio.TimeoutError):
            pass
        started = time.monotonic()
        log("ixian not reachable; waking it and holding the request")
        while time.monotonic() - started < self.a.wait:
            await self.wake()
            await asyncio.sleep(self.a.retry)
            try:
                conn = await self.connect()
                log(f"ixian answered after {time.monotonic() - started:.0f}s; forwarding")
                return conn
            except (OSError, asyncio.TimeoutError):
                continue
        log(f"ixian didn't answer within {self.a.wait}s; dropping the request")
        return None

    @staticmethod
    async def pipe(reader, writer):
        try:
            while data := await reader.read(65536):
                writer.write(data)
                await writer.drain()
        except (ConnectionError, asyncio.CancelledError):
            pass
        finally:
            try:
                writer.close()
            except Exception:
                pass

    def model_list(self, path):
        """The OpenAI-style answer for GET /v1/models or /v1/models/<id>."""
        def entry(m):
            return {"id": m, "object": "model", "owned_by": "ixian"}

        tail = path.split("?", 1)[0].rstrip("/").rsplit("/models", 1)[1].lstrip("/")
        if tail:
            if tail not in self.a.model:
                return 404, {"error": {"message": f"model {tail} not found", "type": "invalid_request_error"}}
            return 200, entry(tail)
        return 200, {"object": "list", "data": [entry(m) for m in self.a.model]}

    async def answer_model_list(self, writer, path):
        status, body = self.model_list(path)
        payload = json.dumps(body).encode()
        reason = "OK" if status == 200 else "Not Found"
        header = (
            f"HTTP/1.1 {status} {reason}\r\nContent-Type: application/json\r\n"
            f"Content-Length: {len(payload)}\r\nConnection: close\r\n\r\n"
        )
        writer.write(header.encode() + payload)
        try:
            await writer.drain()
        finally:
            writer.close()

    async def handle(self, client_reader, client_writer):
        # Read the request head so the request line decides whether a
        # sleeping ixian is worth waking. It is forwarded unchanged.
        try:
            head = await asyncio.wait_for(client_reader.readuntil(b"\r\n\r\n"), timeout=30)
        except (asyncio.IncompleteReadError, asyncio.LimitOverrunError, asyncio.TimeoutError, ConnectionError):
            client_writer.close()
            return
        parts = head.split(b"\r\n", 1)[0].decode("latin-1").split()
        method, path = (parts[0], parts[1]) if len(parts) >= 2 else ("", "")
        listing = method == "GET" and "/models" in path.split("?", 1)[0]

        if listing:
            try:
                upstream = await self.connect()
            except (OSError, asyncio.TimeoutError):
                await self.answer_model_list(client_writer, path)
                return
        else:
            upstream = await self.connect_waking()
        if upstream is None:
            client_writer.close()
            return
        up_reader, up_writer = upstream
        up_writer.write(head)
        await asyncio.gather(
            self.pipe(client_reader, up_writer),
            self.pipe(up_reader, client_writer),
        )


async def serve(args):
    proxy = WakeProxy(args)
    server = await asyncio.start_server(proxy.handle, args.listen_host, args.listen_port)
    log(
        f"wake proxy on {args.listen_host}:{args.listen_port} -> "
        f"{args.upstream_host}:{args.upstream_port} (wait up to {args.wait}s for a wake)"
    )
    async with server:
        await server.serve_forever()


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--listen-host", default="127.0.0.1")
    p.add_argument("--listen-port", type=int, required=True)
    p.add_argument("--upstream-host", required=True)
    p.add_argument("--upstream-port", type=int, required=True)
    p.add_argument("--connect-timeout", type=float, default=2.0)
    p.add_argument("--retry", type=float, default=2.0, help="seconds between connection attempts while waking")
    p.add_argument("--rewake", type=float, default=30.0, help="seconds between magic packets while waking")
    p.add_argument("--wait", type=int, default=300, help="give up on a sleeping ixian after this long")
    p.add_argument("--model", action="append", default=[], help="model id to list while ixian sleeps")
    p.add_argument("wake_cmd", nargs="+", help="command that sends the Wake-on-LAN packet")
    args = p.parse_args()
    asyncio.run(serve(args))


if __name__ == "__main__":
    sys.exit(main())
