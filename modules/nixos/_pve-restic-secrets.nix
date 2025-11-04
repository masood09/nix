{
  sops.secrets = {
    "restic-env" = {
      sopsFile = ./../../secrets/hl-restic.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../secrets/hl-restic.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../secrets/hl-restic.yaml;
    };
  };
}
