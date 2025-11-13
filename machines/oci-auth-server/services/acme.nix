{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "auth.mantannest.com".domain = "auth.mantannest.com";
    };
  };
}
