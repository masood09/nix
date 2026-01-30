{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./_options.nix
  ];

  config = {
    home-manager = {
      extraSpecialArgs = {
        inherit inputs outputs homelabCfg;
      };

      useGlobalPkgs = true;
      useUserPackages = true;

      users = {
        ${homelabCfg.primaryUser.userName} = {
          imports = [
            ./home.nix
          ];
        };
      };
    };
  };
}
