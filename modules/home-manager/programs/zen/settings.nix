# Browser preferences — privacy, network, security, UI, and Zen-specific settings.
_: {
  programs = {
    zen-browser = {
      profiles = {
        default = {
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

            # Privacy — Reduce fingerprinting surface
            "plugins.enumerable_names" = "";
            "browser.search.update" = false;
            "extensions.getAddons.cache.enabled" = false;

            # Privacy — Hide unused addon manager sections
            "extensions.ui.sitepermission.hidden" = true;
            "extensions.ui.locale.hidden" = true;

            # Network — Disable prefetching
            "network.prefetch-next" = false;
            "network.dns.disablePrefetch" = true;
            "network.http.speculative-parallel-limit" = 0;

            # Security — Disable form autofill and password manager
            "extensions.formautofill.addresses.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;
            "signon.rememberSignons" = false;

            # Security — Disable Firefox Sync (also blocked by DisableFirefoxAccounts policy)
            "identity.fxaccounts.enabled" = false;

            # Security — Strict certificate pinning (no MITM exceptions)
            "security.cert_pinning.enforcement_level" = 2;

            # Betterfox overrides — settings that differ from Securefox defaults
            "permissions.default.geo" = 0; # Ask per-site (Securefox blocks all)
            "permissions.default.desktop-notification" = 0; # Ask per-site (Securefox blocks all)
            "dom.security.https_only_mode" = false; # Needed for LAN (e.g. router at http://10.0.1.1)

            # Downloads — Always ask where to save, skip handler prompt
            "browser.download.useDownloadDir" = false;
            "browser.download.always_ask_before_handling_new_types" = false;
            "extensions.postDownloadThirdPartyPrompt" = false;

            # UI — Startup behavior
            "browser.aboutwelcome.enabled" = false;
            "browser.startup.firstrunSkipsHomepage" = true;
            "browser.startup.homepage_override.mstone" = "ignore";
            "trailhead.firstrun.didSeeAboutWelcome" = true;
            "browser.firefox-view.feature-tour" = "{\"screen\":\"\",\"complete\":true}";

            # UI — General
            "browser.ctrlTab.sortByRecentlyUsed" = true;
            "browser.warnOnQuitShortcut" = false;
            "full-screen-api.macos-native-full-screen" = false;
            "full-screen-api.ignore-widgets" = true;
            "layout.spellcheckDefault" = 0;

            # UI — Smooth scrolling (150 = comfortable on niri; 275 caused perceived jank)
            "apz.overscroll.enabled" = true;
            "general.smoothScroll" = true;
            "mousewheel.default.delta_multiplier_y" = 150;

            # Zen — Theme
            "zen.theme.acrylic-elements" = false;
            "zen.theme.border-radius" = 8;
            "zen.theme.content-element-separation" = 0;
            "zen.theme.dark-mode-bias" = 0.3;
            "zen.theme.essentials-favicon-bg" = true;
            "zen.theme.gradient" = true;
            "zen.theme.gradient.show-custom-colors" = false;
            "zen.theme.hide-tab-throbber" = true;
            "zen.theme.show-custom-colors" = false;
            "zen.theme.styled-status-panel" = false;
            "zen.theme.use-system-colors" = false;
            "zen.watermark.enabled" = false;

            # Zen — Compact view and layout
            "zen.view.compact.enable-at-startup" = true;
            "zen.view.compact.animate-sidebar" = false;
            "zen.view.compact.hide-tabbar" = true;
            "zen.view.compact.hide-toolbar" = true;
            "zen.view.experimental-no-window-controls" = true;
            "zen.view.sidebar-expanded" = false;
            "zen.view.use-single-toolbar" = true;

            # Zen — URL bar
            "zen.urlbar.behavior" = "float";
            "zen.urlbar.replace-newtab" = true;

            # Zen — Workspaces
            "zen.welcome-screen.seen" = true;
            "zen.workspaces.continue-where-left-off" = true;
            "zen.workspaces.force-container-workspace" = true;
            "zen.workspaces.natural-scroll" = true;
            "zen.workspaces.separate-essentials" = false;
          };
        };
      };
    };
  };
}
