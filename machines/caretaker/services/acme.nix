{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "homeassistant.mantannest.com".domain = "homeassistant.mantannest.com";
      "chatgpt.mantannest.com".domain = "chatgpt.mantannest.com";
    };
  };
}
