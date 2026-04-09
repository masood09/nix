# Zen Browser — privacy-focused Firefox fork with vertical tabs and workspaces.
# Profile config is split across sub-modules:
#   settings.nix    — browser preferences
#   extensions.nix  — extensions and Zen Mods
#   search.nix      — search engines
#   containers.nix  — container tabs and spaces
#   pins.nix        — pinned tabs
{
  lib,
  pkgs,
  homelabCfg,
  inputs,
  ...
}: {
  imports = [
    ./settings.nix
    ./extensions.nix
    ./search.nix
    ./containers.nix
    ./pins.nix
  ];

  # Workaround for https://github.com/0xc000022070/zen-browser-flake/issues/63
  # MOZ_LEGACY_PROFILES=1 makes Zen skip per-installation profile pinning
  # (installs.ini) and use the default profile from profiles.ini, which is
  # the one Home Manager declares.  See the launchd block below for the
  # macOS-specific half of this workaround.
  home = {
    sessionVariables = {
      MOZ_LEGACY_PROFILES = "1";
    };
  };

  # macOS GUI apps inherit their environment from launchd, not the user's
  # shell, so home.sessionVariables alone does not reach Zen when launched
  # from Spotlight, Finder, or the Dock.  Register a LaunchAgent that runs
  # `launchctl setenv MOZ_LEGACY_PROFILES 1` at login so the variable is
  # exported into the GUI environment for every subsequently-spawned app.
  launchd = lib.mkIf pkgs.stdenv.isDarwin {
    agents = {
      moz-legacy-profiles = {
        inherit (homelabCfg.programs.zen) enable;
        config = {
          Label = "org.nix-community.home.moz-legacy-profiles";
          ProgramArguments = ["/bin/launchctl" "setenv" "MOZ_LEGACY_PROFILES" "1"];
          RunAtLoad = true;
        };
      };
    };
  };

  programs = {
    zen-browser = {
      inherit (homelabCfg.programs.zen) enable;
      setAsDefaultBrowser = true;
      languagePacks = ["en-US"];

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

          # Betterfox — curated Firefox performance, privacy, and UX tweaks.
          # Overrides for conflicts are in settings.nix.
          extraConfig = ''
            ${builtins.readFile "${inputs.betterfox}/Fastfox.js"}
            ${builtins.readFile "${inputs.betterfox}/Securefox.js"}
            ${builtins.readFile "${inputs.betterfox}/Peskyfox.js"}
          '';
        };
      };
    };
  };
}
