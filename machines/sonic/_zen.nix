# sonic — Zen Browser machine-local layout.
#
# Three containers (Personal / Work / Google) with a minimal 2-pin set in
# the Personal space (Karakeep, IT Tools). No Work or Google pins — this
# preserves the pre-refactor `family` branch exactly.
#
# Container IDs, space UUIDs, and pin IDs are stable; do NOT regenerate or
# Zen will treat them as new entities and wipe/duplicate existing session
# state. Values mirror the pre-refactor `family` branch of the shared
# containers.nix and pins.nix.
{config, ...}: let
  user = config.homelab.primaryUser.userName;
  personalSpace = "572910e1-4468-4832-a869-0b3a93e2f165";
  workSpace = "b2f47c1d-8e23-4a91-bc56-7d3e9f0a1c84";
  googleSpace = "a8f3c2e1-5d90-4b2a-9e7f-1c4d8a6b3f9e";
in {
  home-manager = {
    users = {
      ${user} = {
        programs = {
          zen-browser = {
            profiles = {
              default = {
                containersForce = true;
                containers = {
                  Personal = {
                    color = "blue"; # Catppuccin Blue (#89b4fa)
                    icon = "fingerprint";
                    id = 2;
                  };
                  Work = {
                    color = "green"; # Catppuccin Green (#a6e3a1)
                    icon = "briefcase";
                    id = 3;
                  };
                  Google = {
                    color = "yellow"; # Catppuccin Yellow (#f9e2af)
                    icon = "circle";
                    id = 5;
                  };
                };

                spacesForce = true;
                spaces = {
                  "Personal" = {
                    id = personalSpace;
                    icon = "👤";
                    container = 2;
                    position = 1000;
                  };
                  "Work" = {
                    id = workSpace;
                    icon = "💼";
                    container = 3;
                    position = 1001;
                  };
                  "Google" = {
                    id = googleSpace;
                    icon = "🔍";
                    container = 5;
                    position = 1003;
                  };
                };

                pinsForce = true;
                pins = {
                  "Karakeep" = {
                    id = "b2c3d4e5-f6a7-4901-bcde-f12345678901";
                    url = "https://keep.mantannest.com";
                    container = 2;
                    workspace = personalSpace;
                    position = 1;
                  };
                  "IT Tools" = {
                    id = "c3d4e5f6-a7b8-4012-cdef-123456789012";
                    url = "https://ittools.mantannest.com";
                    container = 2;
                    workspace = personalSpace;
                    position = 2;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
