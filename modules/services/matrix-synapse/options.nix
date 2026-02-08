{lib, ...}: {
  options.homelab.services.matrix-synapse = {
    enable = lib.mkEnableOption "Whether to enable Matrix Synapse.";
  };
}
