# Sops secrets — age-encrypted secrets decrypted at activation time.
# The age key lives outside /nix/persist so it survives impermanence rollbacks.
# Machine-specific secrets can override defaultSopsFile in their _config.nix.
{
  sops = {
    defaultSopsFile = ./../../secrets/secrets.sops.yaml;

    age = {
      sshKeyPaths = ["/nix/secret/age/ssh_ed25519_key"];
    };

    secrets = {
      "user/password" = {
        neededForUsers = true;
      };
    };
  };
}
