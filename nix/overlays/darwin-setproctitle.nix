# Overlay — disables setproctitle fork/segfault tests that fail on macOS.
final: prev: {
  python3Packages = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
    setproctitle = pyPrev.setproctitle.overridePythonAttrs (old: {
      disabledTests =
        (old.disabledTests or [])
        ++ final.lib.optionals final.stdenv.isDarwin [
          "test_fork_segfault"
          "test_thread_fork_segfault"
        ];
    });
  });
}
