{
  imports = [
    ./hardware-configuration.nix

    ./../../modules/macos/base.nix
    ./../../modules/home-manager
  ];

  # Host-local override for setproctitle on Darwin
  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
        setproctitle = pyPrev.setproctitle.overridePythonAttrs (old: {
          disabledTests =
            (old.disabledTests or [])
            ++ final.lib.optionals final.stdenv.isDarwin [
              "test_fork_segfault"
              "test_thread_fork_segfault"
            ];
        });
      });
    })
  ];

  homelab = {
    role = "desktop";

    networking = {
      hostName = "murderbot";
    };

    programs = {
      emacs.enable = true;
      git.enable = true;
      neovim.enable = true;
    };
  };
}
