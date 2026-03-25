# Search engines — Brave Search default, Nix ecosystem engines (homelab only), hide built-ins.
{homelabCfg, ...}: let
  isHomelab = homelabCfg.programs.zen.containerProfile == "homelab";
in {
  programs = {
    zen-browser = {
      profiles = {
        default = {
          search = {
            default = "Brave Search";
            privateDefault = "Brave Search";
            force = true;

            engines =
              {
                # Brave Search — privacy-focused default
                "Brave Search" = {
                  urls = [
                    {
                      template = "https://search.brave.com/search";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "https://brave.com/static-assets/images/brave-logo-sans-text.svg";
                  definedAliases = ["@brave"];
                };

                # Hide default engines
                "bing" = {
                  metaData = {
                    hidden = true;
                  };
                };
                "ddg" = {
                  metaData = {
                    hidden = true;
                  };
                };
                "ebay" = {
                  metaData = {
                    hidden = true;
                  };
                };
                "google" = {
                  metaData = {
                    hidden = true;
                  };
                };
                "wikipedia" = {
                  metaData = {
                    hidden = true;
                  };
                };
                "Perplexity" = {
                  metaData = {
                    hidden = true;
                  };
                };
              }
              // (
                if isHomelab
                then {
                  # NixOS Packages — search nixpkgs
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

                  # NixOS Options — search NixOS module options
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

                  # Home Manager Options — search home-manager options
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

                  # My NixOS — search NixOS options and packages together
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

                  # Noogle — search Nix standard library functions
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
                }
                else {}
              );
          };
        };
      };
    };
  };
}
