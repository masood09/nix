# Zen Browser — privacy-focused Firefox fork with vertical tabs and workspaces.
# Configured with strict privacy, Stylix theming, container isolation, workspace tabs,
# UI mods, and productivity extensions.
{
  homelabCfg,
  pkgs,
  lib,
  ...
}: {
  # Enable Stylix theming for Zen browser
  stylix = {
    targets = {
      zen-browser = {
        profileNames = [ "default" ];
      };
    };
  };

  programs = {
    zen-browser = {
      inherit (homelabCfg.programs.zen) enable;
      setAsDefaultBrowser = true;

      # Policies (Firefox-compatible enterprise policies)
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableFormHistory = true;
        DisplayBookmarksToolbar = "newtab";
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;

        # Privacy settings
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };

        # DNS over HTTPS — disabled, using system DNS
        DNSOverHTTPS = {
          Enabled = false;
          ProviderURL = "https://private.canadianshield.cira.ca/dns-query";
          Locked = false;
        };
      };

      # Browser profiles
      profiles = {
        default = {
          id = 0;
          isDefault = true;

          # Extensions (using nur firefox-addons)
          extensions = lib.mkIf (pkgs ? nur) (with pkgs.nur.repos.rycee.firefox-addons; [
            # Privacy & Ad Blocking
            # adnauseam - Not in NUR, needs manual installation
            sponsorblock          # Skip YouTube sponsorships
            clearurls            # Remove tracking parameters

            # Productivity
            vimium               # Vim keyboard navigation
            auto-tab-discard     # Suspend inactive tabs
            stylus               # Custom CSS styles
          ]);

          # Browser settings (preferences)
          settings = {
            # Privacy — Strict tracking protection
            "browser.contentblocking.category" = "strict";
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.query_stripping.enabled" = true;
            "privacy.query_stripping.enabled.pbmode" = true;
            "privacy.bounceTrackingProtection.mode" = 1;

            # Network — Disable prefetching
            "network.prefetch-next" = false;
            "network.dns.disablePrefetch" = true;
            "network.http.speculative-parallel-limit" = 0;

            # Security — Disable form autofill and password manager
            "extensions.formautofill.addresses.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;
            "signon.rememberSignons" = false;

            # UI — Disable animations for performance
            "full-screen-api.macos-native-full-screen" = false;
            "full-screen-api.ignore-widgets" = true;
            "browser.warnOnQuitShortcut" = false;

            # Downloads — Always ask where to save
            "browser.download.useDownloadDir" = false;

            # Zen-specific settings
            "zen.view.sidebar-expanded" = false;
            "zen.view.compact.enable-at-startup" = false;
            "zen.view.use-single-toolbar" = false;
            "zen.workspaces.force-container-workspace" = true;
            "zen.workspaces.separate-essentials" = false;
            "zen.workspaces.continue-where-left-off" = true;
            "zen.view.compact.animate-sidebar" = false;
            "zen.welcome-screen.seen" = true;
            "zen.workspaces.natural-scroll" = true;
            "zen.view.compact.hide-tabbar" = true;
            "zen.view.compact.hide-toolbar" = true;
            "zen.urlbar.behavior" = "float";

            # Disable spellcheck
            "layout.spellcheckDefault" = 0;
          };

          # Zen Mods — UI/UX enhancements from the Zen Mods marketplace
          mods = [
            "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
            "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
            "7190e4e9-bead-4b40-8f57-95d852ddc941" # Tab title fixes
            "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
            "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
            "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar
            "c6813222-6571-4ba6-8faf-58f3343324f6" # Disable Rounded Corners
            "c8d9e6e6-e702-4e15-8972-3596e57cf398" # Zen Back Forward
            "cb15abdb-0514-4e09-8ce5-722cf1f4a20f" # Hide Extension Name
            "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
            "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
            "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
            "fd24f832-a2e6-4ce9-8b19-7aa888eb7f8e" # Quietify
          ];

          # Search engines
          search = {
            default = "Brave Search";
            force = true;

            engines = {
              # Brave Search (default)
              "Brave Search" = {
                urls = [{
                  template = "https://search.brave.com/search";
                  params = [
                    { name = "q"; value = "{searchTerms}"; }
                  ];
                }];
                icon = "https://cdn.search.brave.com/serp/v2/_app/immutable/assets/brave-logo-sans-text.BLBlv3Aj.svg";
                definedAliases = [ "@brave" ];
              };
            };
          };

          # Container tabs — isolate browsing contexts with Catppuccin colors
          containersForce = true;
          containers = {
            Personal = {
              color = "blue";        # Catppuccin Blue (#89b4fa)
              icon = "fingerprint";
              id = 2;
            };

            Homelab = {
              color = "green";       # Catppuccin Green (#a6e3a1)
              icon = "tree";
              id = 3;
            };

            Admin = {
              color = "red";         # Catppuccin Red (#f38ba8)
              icon = "briefcase";
              id = 4;
            };

            Google = {
              color = "yellow";      # Catppuccin Yellow (#f9e2af)
              icon = "circle";
              id = 5;
            };
          };

          # Zen Spaces — workspace tabs linked to containers
          spacesForce = true;
          spaces = {
            "Personal" = {
              id = "572910e1-4468-4832-a869-0b3a93e2f165";
              icon = "👤";
              container = 2;  # Personal container
              position = 1000;
            };

            "Homelab" = {
              id = "ec287d7f-d910-4860-b400-513f269dee77";
              icon = "🌲";
              container = 3;  # Homelab container
              position = 1001;
            };

            "Admin" = {
              id = "2441acc9-79b1-4afb-b582-ee88ce554ec0";
              icon = "💼";
              container = 4;  # Admin container
              position = 1002;
            };

            "Google" = {
              id = "a8f3c2e1-5d90-4b2a-9e7f-1c4d8a6b3f9e";
              icon = "🔍";
              container = 5;  # Google container
              position = 1003;
            };
          };
        };
      };
    };
  };
}
