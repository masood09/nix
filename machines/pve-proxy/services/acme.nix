{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "passwords.mantannest.com".domain = "passwords.mantannest.com";
      "photos.mantannest.com".domain = "photos.mantannest.com";
    };
  };
}
