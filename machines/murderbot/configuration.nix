{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./hardware-configuration.nix

    ./../../modules/macos/base.nix
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
    networking = {
      hostName = "murderbot";
    };

    programs = {
      emacs.enable = true;
      neovim.enable = true;
    };

    role = "desktop";
    isEncryptedRoot = false;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs homelabCfg;
    };

    useGlobalPkgs = true;
    useUserPackages = true;

    users = {
      ${homelabCfg.primaryUser.userName} = {
        imports = [
          ./../../modules/home-manager
        ];
      };
    };
  };
}
