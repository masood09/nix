{
  nix.distributedBuilds = true;

  nix.settings = {
    builders-use-substitutes = true;
  };

  nix.buildMachines = [
    {
      hostName = "pve-nix-builder";
      mandatoryFeatures = [ ];
      maxJobs = 3;
      protocol = "ssh-ng";
      speedFactor = 6;
      sshUser = "remotebuild";
      sshKey = "/etc/ssh/ssh_host_ed25519_key";
      system = "x86_64-linux";
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }
  ];
}
