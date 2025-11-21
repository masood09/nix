{lib, ...}: {
  options.homelab = {
    programs = {
      git = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable git.
          '';
        };

        userName = lib.mkOption {
          default = "Masood Ahmed";
          type = lib.types.str;
          description = ''
            The userName option for git.
          '';
        };

        userEmail = lib.mkOption {
          default = "me@ahmedmasood.com";
          type = lib.types.str;
          description = ''
            The userEmail option for git.
          '';
        };
      };
    };
  };
}
