{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "headscale.mantannest.com".domain = "headscale.mantannest.com";
    };
  };
}
