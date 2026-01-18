{
  sops = {
    defaultSopsFile = ./../../secrets/secrets.yaml;
    age.sshKeyPaths = ["/nix/secret/age/ssh_ed25519_key"];

    secrets."user-password".neededForUsers = true;
    secrets."user-password" = {};
  };
}
