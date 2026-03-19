# Zen Browser — Firefox-based browser wrapped with declarative settings.
# Uses wrapFirefox to bake in privacy prefs, extensions, and Brave as
# default search engine. Extensions are auto-installed from AMO on first launch.
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  zenEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;

  # Helper to declare a Firefox/Zen extension by its AMO short-id and GUID
  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  # Locked preferences — applied via autoconfig and cannot be changed in about:config
  prefs = {
    "extensions.autoDisableScopes" = 0;

    "browser.contentblocking.category" = "strict";

    # Global Privacy Control (GPC)
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.globalprivacycontrol.functionality.enabled" = true;
    "privacy.donottrackheader.enabled" = true;

    # Bitwarden handles passwords — disable built-in password manager
    "signon.rememberSignons" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.addresses.enabled" = false;

    # DNS over HTTPS off (handled at network level)
    "network.trr.mode" = 5;

    # No telemetry
    "toolkit.telemetry.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;

    "extensions.pocket.enabled" = false;
  };

  extensions = [
    (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
    (extension "adnauseam" "adnauseam@rednoise.org")
    (extension "auto-tab-discard" "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}")
    (extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}")
    (extension "karakeep" "addon@karakeep.app")
    (extension "sponsorblock" "sponsorBlocker@ajay.app")
    (extension "styl-us" "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}")
    (extension "vimium-ff" "{d7742d87-e61d-4b78-b8a1-b469842139fa}")
    (extension "catppuccin-web-file-icons" "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}")
  ];
in {
  config = lib.mkIf zenEnabled {
    home.packages = [
      (pkgs.wrapFirefox
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
        {
          # Lock prefs so they persist across profile resets
          extraPrefs = lib.concatLines (
            lib.mapAttrsToList (
              name: value: ''lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});''
            ) prefs
          );

          extraPolicies = {
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            DontCheckDefaultBrowser = true;

            ExtensionSettings = builtins.listToAttrs extensions;

            # Brave Search as default (privacy-respecting, no Google)
            SearchEngines = {
              Default = "Brave";
              Add = [
                {
                  Name = "Brave";
                  URLTemplate = "https://search.brave.com/search?q={searchTerms}";
                  IconURL = "https://cdn.search.brave.com/serp/v2/_app/immutable/assets/brave-search-icon.CsIFM2aN.svg";
                  Alias = "@brave";
                  Method = "GET";
                }
              ];
            };
          };
        })
    ];
  };
}
