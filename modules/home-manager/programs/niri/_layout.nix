# Niri layout and decoration defaults — the `programs.niri.settings.layout`
# value. Not a Home Manager module: this is a plain function returning an
# attrset, imported by ./default.nix. Stylix owns the palette where possible so
# focus/tab accents follow the active theme; the non-Stylix arms are the
# fallback for machines with homelab.stylix.enable = false.
{
  config,
  lib,
  stylixEnabled,
  ...
}: {
  gaps = 12;
  background-color = "transparent";
  center-focused-column = "never";

  focus-ring =
    {
      enable = true;
      width = 3;
    }
    // lib.optionalAttrs stylixEnabled {
      active = {
        color = config.lib.stylix.colors.withHashtag.base13;
      };
      inactive = {
        color = config.lib.stylix.colors.withHashtag.base02;
      };
      urgent = {
        color = config.lib.stylix.colors.withHashtag.base08;
      };
    };

  tab-indicator =
    {
      enable = true;
    }
    // lib.optionalAttrs stylixEnabled {
      active = {
        color = config.lib.stylix.colors.withHashtag.base13;
      };
      inactive = {
        color = config.lib.stylix.colors.withHashtag.base04;
      };
      urgent = {
        color = config.lib.stylix.colors.withHashtag.base08;
      };
    };

  insert-hint =
    {
      enable = true;
    }
    // lib.optionalAttrs stylixEnabled {
      display = {
        color = "${config.lib.stylix.colors.withHashtag.base13}80";
      };
    };

  preset-column-widths = [
    {proportion = 0.33333;}
    {proportion = 0.5;}
    {proportion = 0.66667;}
  ];

  default-column-width = {
    proportion = 0.5;
  };

  border = {
    enable = false;
  };

  shadow = {
    enable = false;
  };

  struts = {};
}
