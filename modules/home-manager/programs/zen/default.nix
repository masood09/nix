# Zen Browser — privacy-focused Firefox fork with vertical tabs and workspaces.
# Profile config is split across sub-modules:
#   settings.nix    — browser preferences
#   extensions.nix  — extensions and Zen Mods
#   search.nix      — search engines
#   containers.nix  — container tabs and spaces
#   pins.nix        — pinned tabs
{
  homelabCfg,
  ...
}: {
  imports = [
    ./settings.nix
    ./extensions.nix
    ./search.nix
    ./containers.nix
    ./pins.nix
  ];

  # Enable Stylix theming for Zen browser
  stylix = {
    targets = {
      zen-browser = {
        profileNames = ["default"];
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

        # Security — Disable autofill for sensitive data
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;

        # UX — Disable update prompts and default browser checks
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DontCheckDefaultBrowser = true;

        # Privacy — Tracking protection
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };

        # Privacy — Clear data on browser shutdown
        SanitizeOnShutdown = {
          FormData = true;
          Cache = true;
        };

        # DNS over HTTPS — disabled, using system DNS
        DNSOverHTTPS = {
          Enabled = false;
          ProviderURL = "https://private.canadianshield.cira.ca/dns-query";
          Locked = false;
        };
      };

      profiles = {
        default = {
          id = 0;
          isDefault = true;
        };
      };
    };
  };
}
