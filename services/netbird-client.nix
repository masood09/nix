{
  services.netbird.enable = true;

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/netbird"
    ];
  };
}
