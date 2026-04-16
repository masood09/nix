# usul — Zen Browser machine-local layout.
#
# Four containers (Personal / Homelab / Admin / Google) with the full
# homelab pin set (Proton suite, Karakeep, homelab dashboards, Authentik,
# Gmail/YouTube) and the NixOS ecosystem search engines (Packages, Options,
# HM Options, My NixOS, Noogle).
#
# Container IDs, space UUIDs, and pin IDs are stable; do NOT regenerate or
# Zen will treat them as new entities and wipe/duplicate existing session
# state. Values mirror the pre-refactor `homelab` branch of the shared
# containers.nix, pins.nix, and search.nix.
{config, ...}: let
  user = config.homelab.primaryUser.userName;
  personalSpace = "572910e1-4468-4832-a869-0b3a93e2f165";
  homelabSpace = "ec287d7f-d910-4860-b400-513f269dee77";
  adminSpace = "2441acc9-79b1-4afb-b582-ee88ce554ec0";
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
                  "Homelab" = {
                    id = homelabSpace;
                    icon = "🌲";
                    container = 3;
                    position = 1001;
                  };
                  "Admin" = {
                    id = adminSpace;
                    icon = "💼";
                    container = 4;
                    position = 1002;
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
                  # --- Personal space ---
                  "Proton Mail" = {
                    id = "a1b2c3d4-e5f6-4890-abcd-ef1234567890";
                    url = "https://mail.proton.me/";
                    container = 2;
                    workspace = personalSpace;
                    position = 1;
                  };
                  "Proton Calendar" = {
                    id = "3825a39a-656b-4625-a226-d20964b39cf3";
                    url = "https://calendar.proton.me";
                    container = 2;
                    workspace = personalSpace;
                    position = 2;
                  };
                  "Karakeep" = {
                    id = "b2c3d4e5-f6a7-4901-bcde-f12345678901";
                    url = "https://keep.mantannest.com";
                    container = 2;
                    workspace = personalSpace;
                    position = 3;
                  };
                  "IT Tools" = {
                    id = "c3d4e5f6-a7b8-4012-cdef-123456789012";
                    url = "https://ittools.mantannest.com";
                    container = 2;
                    workspace = personalSpace;
                    position = 4;
                  };
                  "Mail Archiver" = {
                    id = "f6a7b8c9-d0e1-4345-f012-456789012345";
                    url = "https://mailarchiver.mantannest.com";
                    container = 2;
                    workspace = personalSpace;
                    position = 5;
                  };

                  # --- Homelab space ---
                  "UniFi" = {
                    id = "a7b8c9d0-e1f2-4456-0123-567890123456";
                    url = "https://unifi.ui.com";
                    container = 3;
                    workspace = homelabSpace;
                    position = 1;
                  };
                  "Omada Controller" = {
                    id = "a5ad6de6-e610-44c2-86f5-a8720de88c5f";
                    url = "https://omada-host.mgmt.homelab.mantannest.com:8043";
                    container = 3;
                    workspace = homelabSpace;
                    position = 2;
                  };
                  "Uptime Kuma - Prod" = {
                    id = "b8c9d0e1-f2a3-4567-1234-678901234567";
                    url = "https://uptime.mantannest.com";
                    container = 3;
                    workspace = homelabSpace;
                    position = 3;
                  };
                  "Grafana - Prod" = {
                    id = "4f7c2d91-8e3a-4b6f-a1d4-92c5e7f8b103";
                    url = "https://grafana.mantannest.com";
                    container = 3;
                    workspace = homelabSpace;
                    position = 4;
                  };
                  "Uptime Kuma - Test" = {
                    id = "c9d0e1f2-a3b4-4678-2345-789012345678";
                    url = "https://uptime.test.mantannest.com";
                    container = 3;
                    workspace = homelabSpace;
                    position = 5;
                  };
                  "Grafana - Test" = {
                    id = "9a1e6c44-2b7f-4d8a-b5c9-1f3e7a2d6b80";
                    url = "https://grafana.test.mantannest.com";
                    container = 3;
                    workspace = homelabSpace;
                    position = 6;
                  };
                  "Oracle Cloud" = {
                    id = "e2c1d9e9-fe41-4bae-aca6-5a42b6526138";
                    url = "https://cloud.oracle.com";
                    container = 3;
                    workspace = homelabSpace;
                    position = 7;
                  };
                  "Backblaze" = {
                    id = "4bff4f82-d95a-4985-984c-0893ea38c9f8";
                    url = "https://secure.backblaze.com/b2_buckets.htm";
                    container = 3;
                    workspace = homelabSpace;
                    position = 8;
                  };

                  # --- Admin space ---
                  "Authentik - Prod" = {
                    id = "d0e1f2a3-b4c5-4789-3456-890123456789";
                    url = "https://auth.mantannest.com";
                    container = 4;
                    workspace = adminSpace;
                    position = 1;
                  };
                  "Authentik - Test" = {
                    id = "e1f2a3b4-c5d6-4890-4567-901234567890";
                    url = "https://auth.test.mantannest.com";
                    container = 4;
                    workspace = adminSpace;
                    position = 2;
                  };

                  # --- Google space ---
                  "GMail" = {
                    id = "d4e5f6a7-b8c9-4123-def0-234567890123";
                    url = "https://mail.google.com";
                    container = 5;
                    workspace = googleSpace;
                    position = 1;
                  };
                  "YouTube" = {
                    id = "e5f6a7b8-c9d0-4234-ef01-345678901234";
                    url = "https://youtube.com";
                    container = 5;
                    workspace = googleSpace;
                    position = 2;
                  };
                };

                # NixOS ecosystem search engines — usul-only because it is
                # the sole machine that does homelab/Nix development work.
                # Merges with the Brave default + hidden built-ins defined
                # in modules/home-manager/programs/zen/search.nix.
                search = {
                  engines = {
                    "NixOS Packages" = {
                      urls = [
                        {
                          template = "https://search.nixos.org/packages";
                          params = [
                            {
                              name = "channel";
                              value = "unstable";
                            }
                            {
                              name = "query";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                      icon = "https://nixos.org/favicon.png";
                      definedAliases = ["@nixpkgs"];
                    };

                    "NixOS Options" = {
                      urls = [
                        {
                          template = "https://search.nixos.org/options";
                          params = [
                            {
                              name = "channel";
                              value = "unstable";
                            }
                            {
                              name = "query";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                      icon = "https://nixos.org/favicon.png";
                      definedAliases = ["@nixopts"];
                    };

                    "Home Manager Options" = {
                      urls = [
                        {
                          template = "https://home-manager-options.extranix.com";
                          params = [
                            {
                              name = "query";
                              value = "{searchTerms}";
                            }
                            {
                              name = "release";
                              value = "master";
                            }
                          ];
                        }
                      ];
                      icon = "https://nixos.org/favicon.png";
                      definedAliases = ["@hm"];
                    };

                    "My NixOS" = {
                      urls = [
                        {
                          template = "https://mynixos.com/search";
                          params = [
                            {
                              name = "q";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                      icon = "https://nixos.org/favicon.png";
                      definedAliases = ["@mynixos"];
                    };

                    "Noogle" = {
                      urls = [
                        {
                          template = "https://noogle.dev/q";
                          params = [
                            {
                              name = "term";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                      icon = "https://nixos.org/favicon.png";
                      definedAliases = ["@noogle"];
                    };
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
