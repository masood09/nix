# Element Desktop — Matrix client managed through Home Manager's native module.
# Keep this separate from the generic package list so we can use the upstream
# HM options (`enable`, `package`, `settings`, `profiles`) when we need them.
# For now we only override the package to force Electron onto GNOME Keyring in
# the Niri session, where desktop auto-detection would otherwise miss libsecret.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.element-desktop;

  elementDesktopWithKeyring = pkgs.symlinkJoin {
    name = "element-desktop-with-keyring";
    paths = [pkgs.element-desktop];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/element-desktop" \
        --add-flags "--password-store=gnome-libsecret"
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    programs.element-desktop = {
      enable = true;
      # Electron's desktop auto-detection misses our Niri session on Linux, so
      # force libsecret there. macOS uses the stock package because Keychain
      # integration is native and does not need the Electron flag override.
      package =
        if pkgs.stdenv.isLinux
        then elementDesktopWithKeyring
        else pkgs.element-desktop;

      # Home Manager writes this as Element's config.json, which replaces the
      # packaged defaults rather than merging with them. Keep the baseline here
      # intentionally fuller than a minimal three-key override. This profile is
      # shared by every machine that opts into homelab.programs.element-desktop,
      # so per-machine divergence should happen by adding profiles/options here
      # rather than hand-editing local Element state.
      settings = {
        brand = "Element";
        default_theme = "dark";
        disable_3pid_login = false;
        disable_custom_urls = true;
        disable_guests = true;
        disable_login_language_selector = false;
        force_verification = false;
        show_labs_settings = false;

        default_server_config = {
          "m.homeserver" = {
            base_url = "https://chat.mantannest.com";
            server_name = "chat.mantannest.com";
          };
        };

        # Keep analytics off by omission: do not define posthog here.
        integrations_ui_url = "https://scalar.vector.im/";
        integrations_rest_url = "https://scalar.vector.im/api";
      };
    };
  };
}
