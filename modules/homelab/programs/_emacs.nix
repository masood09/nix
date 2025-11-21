{lib, ...}: {
  options.homelab = {
    programs = {
      emacs = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = ''
            Whether to enable emacs.
          '';
        };
      };
    };
  };
}
