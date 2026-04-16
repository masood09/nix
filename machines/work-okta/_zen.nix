# work-okta — Zen Browser machine-local layout.
#
# Minimal two-container layout (Personal / Work), no pinned tabs, no Google
# container, and an ExtensionSettings policy that blocks three extensions
# that aren't appropriate on a work machine (Karakeep, SponsorBlock,
# Bitwarden). Mirrors the pre-refactor `work-minimal` branch plus the
# previously inlined ExtensionSettings block from `default.nix`.
#
# Container IDs and space UUIDs are stable; do NOT regenerate or Zen will
# treat them as new entities and wipe/duplicate existing session state.
# Work-space UUID intentionally matches sonic so the "Work" concept is
# consistent across machines; the container and space are still scoped
# per-profile.
{config, ...}: let
  user = config.homelab.primaryUser.userName;
  personalSpace = "572910e1-4468-4832-a869-0b3a93e2f165";
  workSpace = "b2f47c1d-8e23-4a91-bc56-7d3e9f0a1c84";
in {
  home-manager = {
    users = {
      ${user} = {
        programs = {
          zen-browser = {
            # Extension block — enforced via Firefox-style ExtensionSettings
            # policy so the three IDs below cannot be installed even if the
            # user attempts to add them via the Add-ons page. IDs must match
            # the AMO/Mozilla addon manifest exactly; typos silently no-op.
            policies = {
              ExtensionSettings = {
                # Karakeep — personal bookmark manager, not needed on work.
                "addon@karakeep.app" = {
                  installation_mode = "blocked";
                };
                # SponsorBlock — YouTube sponsor skipper, not needed on work.
                "sponsorBlocker@ajay.app" = {
                  installation_mode = "blocked";
                };
                # Bitwarden — work machine uses corporate password tooling.
                "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                  installation_mode = "blocked";
                };
              };
            };

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
                };

                # Positively assert "no pins" so the activation script does
                # not inherit anything from upstream defaults.
                pinsForce = true;
                pins = {};
              };
            };
          };
        };
      };
    };
  };
}
