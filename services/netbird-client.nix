{
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
  };
in {
  services.netbird = {
    package = pkgs-unstable.netbird;
    enable = true;
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/netbird"
    ];
  };
}
