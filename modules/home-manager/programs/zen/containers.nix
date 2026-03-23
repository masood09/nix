# Container tabs and Zen Spaces — profile-scoped browsing contexts with Catppuccin colors.
# Space UUIDs are stable so Zen can persist workspace state across rebuilds.
# "homelab" (default): Personal, Homelab, Admin, Google.
# "family" / "work":   Personal, Work, Google.
{homelabCfg, ...}: {
  programs = {
    zen-browser = {
      profiles = {
        default = {
          containersForce = true;
          containers =
            {
              Personal = {
                color = "blue"; # Catppuccin Blue (#89b4fa)
                icon = "fingerprint";
                id = 2;
              };

              Google = {
                color = "yellow"; # Catppuccin Yellow (#f9e2af)
                icon = "circle";
                id = 5;
              };
            }
            // (
              if builtins.elem homelabCfg.programs.zen.containerProfile ["family" "work"]
              then {
                Work = {
                  color = "green"; # Catppuccin Green (#a6e3a1)
                  icon = "briefcase";
                  id = 3;
                };
              }
              else {
                Homelab = {
                  color = "green"; # Catppuccin Green (#a6e3a1)
                  icon = "tree";
                  id = 3;
                };

                Admin = {
                  color = "red"; # Catppuccin Red (#f38ba8)
                  icon = "briefcase";
                  id = 4;
                };
              }
            );

          spacesForce = true;
          spaces =
            {
              "Personal" = {
                id = "572910e1-4468-4832-a869-0b3a93e2f165";
                icon = "👤";
                container = 2; # Personal container
                position = 1000;
              };

              "Google" = {
                id = "a8f3c2e1-5d90-4b2a-9e7f-1c4d8a6b3f9e";
                icon = "🔍";
                container = 5; # Google container
                position = 1003;
              };
            }
            // (
              if builtins.elem homelabCfg.programs.zen.containerProfile ["family" "work"]
              then {
                "Work" = {
                  id = "b2f47c1d-8e23-4a91-bc56-7d3e9f0a1c84";
                  icon = "💼";
                  container = 3; # Work container
                  position = 1001;
                };
              }
              else {
                "Homelab" = {
                  id = "ec287d7f-d910-4860-b400-513f269dee77";
                  icon = "🌲";
                  container = 3; # Homelab container
                  position = 1001;
                };

                "Admin" = {
                  id = "2441acc9-79b1-4afb-b582-ee88ce554ec0";
                  icon = "💼";
                  container = 4; # Admin container
                  position = 1002;
                };
              }
            );
        };
      };
    };
  };
}
