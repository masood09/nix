{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "homeassistant.mantannest.com".domain = "homeassistant.mantannest.com";
      "dockge.caretaker.server.homelab.mantannest.com".domain = "dockge.caretaker.server.homelab.mantannest.com";
    };
  };
}
