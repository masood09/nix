{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "auth.mantannest.com".domain = "auth.mantannest.com";
      "headscale.mantannest.com".domain = "headscale.mantannest.com";
    };
  };
}
