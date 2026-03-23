# Search engines — Brave Search as default with alias.
{...}: {
  programs = {
    zen-browser = {
      profiles = {
        default = {
          search = {
            default = "Brave Search";
            force = true;

            engines = {
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
                icon = "https://cdn.search.brave.com/serp/v2/_app/immutable/assets/brave-logo-sans-text.BLBlv3Aj.svg";
                definedAliases = ["@brave"];
              };
            };
          };
        };
      };
    };
  };
}
