{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  zenEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;

  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  prefs = {
    # Auto-enable extensions without prompting
    "extensions.autoDisableScopes" = 0;

    # Privacy: strict
    "browser.contentblocking.category" = "strict";

    # Tell websites not to sell/share data (GPC)
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.globalprivacycontrol.functionality.enabled" = true;
    "privacy.donottrackheader.enabled" = true;

    # Disable saving passwords
    "signon.rememberSignons" = false;

    # Disable autofill payments and addresses
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.addresses.enabled" = false;

    # Disable DNS over HTTPS
    "network.trr.mode" = 5;

    # Telemetry off
    "toolkit.telemetry.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;

    # Disable Pocket
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
