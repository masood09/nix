# Home-manager integration — wires up the primary user's home environment.
# Passes homelabCfg and flake inputs to all home-manager modules so they
# can conditionally enable programs based on machine role/options.
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
      # Make homelabCfg + flake inputs available in all HM modules
      extraSpecialArgs = {
        inherit inputs outputs homelabCfg;
      };

      # Share the system's nixpkgs instance (no duplicate eval)
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
