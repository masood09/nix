# Extensions and Zen Mods — privacy, productivity, theming, and UI enhancements.
# Extensions are force-installed via ExtensionSettings policy.
# Zen Mods are installed via the Zen Mods marketplace.
_: {
  programs = {
    zen-browser = {
      policies = {
        # Extensions — block manual installs, allow only Nix-managed extensions
        ExtensionSettings = {
          "*" = {
            blocked_install_message = "Extensions must be added via Nix config";
            installation_mode = "blocked";
          };
          # AdNauseam — ad blocker + tracking obfuscation
          "adnauseam@rednoise.org" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/adnauseam/latest.xpi";
            private_browsing = true;
            default_area = "navbar";
            permissions = ["alarms" "dns" "menus" "privacy" "storage" "tabs" "unlimitedStorage" "webNavigation" "webRequest" "webRequestBlocking" "management"];
            origins = ["<all_urls>"];
          };
          # Vimium — vim keyboard navigation
          "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
            private_browsing = true;
            default_area = "navbar";
            permissions = ["tabs" "bookmarks" "history" "storage" "sessions" "notifications" "scripting" "webNavigation" "search" "clipboardRead" "clipboardWrite"];
            origins = ["<all_urls>"];
          };
          # DeArrow — crowdsourced clickbait replacement
          "deArrow@ajay.app" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/dearrow/latest.xpi";
            private_browsing = true;
            default_area = "navbar";
            permissions = ["storage" "unlimitedStorage" "alarms" "scripting"];
            origins = ["https://sponsor.ajay.app/*" "https://dearrow-thumb.ajay.app/*" "https://*.googlevideo.com/*" "https://*.youtube.com/*" "https://www.youtube-nocookie.com/embed/*" "*://*/*"];
          };
          # SponsorBlock — skip YouTube sponsorships
          "sponsorBlocker@ajay.app" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
            private_browsing = true;
            default_area = "navbar";
            permissions = ["storage" "scripting" "unlimitedStorage"];
            origins = ["https://sponsor.ajay.app/*" "*://*/*"];
          };
          # Stylus — custom CSS styles
          "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi";
            private_browsing = true;
            permissions = ["alarms" "contextMenus" "storage" "tabs" "unlimitedStorage" "webNavigation" "webRequest" "webRequestBlocking"];
            origins = ["<all_urls>"];
          };
          # Catppuccin Web File Icons
          "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/catppuccin-web-file-icons/latest.xpi";
            private_browsing = true;
            permissions = ["storage" "contextMenus" "activeTab"];
          };
          # Bitwarden — password manager
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            private_browsing = true;
            default_area = "navbar";
            permissions = ["alarms" "clipboardRead" "clipboardWrite" "contextMenus" "idle" "storage" "tabs" "unlimitedStorage" "webNavigation" "webRequest" "webRequestBlocking" "notifications" "nativeMessaging"];
            origins = ["<all_urls>" "*://*/*"];
          };
          # Consent-O-Matic — auto-decline GDPR cookie banners
          "gdpr@cavi.au.dk" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/consent-o-matic/latest.xpi";
            private_browsing = true;
            permissions = ["activeTab" "tabs" "storage"];
            origins = ["<all_urls>"];
          };
          # ClearURLs — strip tracking parameters from URLs
          "{74145f27-f039-47ce-a470-a662b129930a}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
            private_browsing = true;
            permissions = ["webRequest" "webRequestBlocking" "storage" "unlimitedStorage" "contextMenus" "webNavigation" "tabs" "downloads"];
            origins = ["<all_urls>"];
          };
          # Karakeep — self-hosted bookmark manager
          "addon@karakeep.app" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/karakeep/latest.xpi";
            private_browsing = true;
            default_area = "navbar";
            permissions = ["storage" "tabs" "contextMenus"];
          };
        };

        # Extension policies — pre-configure extensions via managed storage
        "3rdparty" = {
          Extensions = {
            "adnauseam@rednoise.org" = {
              userSettings = [
                ["hidingAds" "true"]
                ["clickingAds" "true"]
                ["blockingMalware" "true"]
                ["disableClickingForDNT" "true"]
                ["blurCollectedAds" "true"]
                ["noOutgoingCookies" "true"]
                ["noOutgoingReferer" "true"]
                ["noOutgoingUserAgent" "true"]
                ["tooltipsDisabled" "true"]
                ["webrtcIPAddressHidden" "false"]
              ];
            };
          };
        };
      };

      profiles = {
        default = {
          # Zen Mods — UI/UX enhancements from the Zen Mods marketplace
          mods = [
            "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
            "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
            "7190e4e9-bead-4b40-8f57-95d852ddc941" # Tab title fixes
            "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
            "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
            "c6813222-6571-4ba6-8faf-58f3343324f6" # Disable Rounded Corners
            "c8d9e6e6-e702-4e15-8972-3596e57cf398" # Zen Back Forward
            "cb15abdb-0514-4e09-8ce5-722cf1f4a20f" # Hide Extension Name
            "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
            "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
            "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
            "fd24f832-a2e6-4ce9-8b19-7aa888eb7f8e" # Quietify
          ];
        };
      };
    };
  };
}
