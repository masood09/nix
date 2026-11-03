# Options — Tailscale VPN client (login server, ZFS).
{lib, ...}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        tailscale = {
          enable = lib.mkEnableOption "Whether to enable Tailscale.";

          loginServer = lib.mkOption {
            type = lib.types.str;
            default = "https://headscale.mantannest.com";
            description = "Control server URL passed to `tailscale up --login-server`.";
          };

          acceptRoutes = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether to accept subnet routes advertised on the tailnet. Off by
              default: servers reach each other over tailnet IPs, and a host
              that sits inside an advertised subnet must not accept it, because
              the accepted route outranks the directly connected LAN route, so
              replies to LAN clients are sent into the tunnel and LAN
              connections hang. Enable only on roaming clients that need to
              reach a remote subnet through a subnet router.
            '';
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/tailscale";
            description = "Tailscale state directory. If ZFS is enabled, the dataset is mounted here.";
          };

          zfs = zfsOpts {
            serviceName = "Tailscale";
            dataset = "rpool/root/var/lib/tailscale";
            properties = {
              recordsize = "16K";
            };
          };
        };
      };
    };
  };
}
