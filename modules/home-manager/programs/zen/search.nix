# Search engines — Brave Search default + hide noisy built-ins.
#
# Machine-specific engines (e.g. the NixOS ecosystem search engines on usul)
# live in that machine's `_zen.nix` and merge with this attrset at activation.
_: {
  programs = {
    zen-browser = {
      profiles = {
        default = {
          search = {
            default = "Brave Search";
            privateDefault = "Brave Search";
            force = true;

            engines = {
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
            };
          };
        };
      };
    };
  };
}
