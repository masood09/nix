# Sops secret declarations — paths, owners, and restart triggers for this machine.
{
  config = {
    sops = {
      secrets = {
        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        "tailscale/preauth-key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        # Encryption keys of the data pools' container datasets
        # (keylocation file:///run/secrets/<pool>_key, disko/default.nix).
        "cipool_key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "agentpool_key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        # ZFS event notifications (modules/nixos/zfs/notification.nix).
        "zed/discord-zfs-webhook" = {};
      };
    };
  };
}
