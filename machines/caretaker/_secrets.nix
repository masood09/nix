# Sops secret declarations — paths, owners, and restart triggers for this machine.
{
  config.sops.secrets = {
    "alloy/.env" = {
      restartUnits = ["alloy.service"];
    };

    "tailscale/preauth-key" = {
      sopsFile = ./secrets.sops.yaml;
    };
  };
}
