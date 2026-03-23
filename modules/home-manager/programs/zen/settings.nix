# Browser preferences — privacy, network, security, UI, and Zen-specific settings.
{...}: {
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
        };
      };
    };
  };
}
