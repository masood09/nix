{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "homeassistant.mantannest.com".domain = "homeassistant.mantannest.com";
    };
  };
}
