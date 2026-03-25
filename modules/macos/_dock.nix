# Dock management — declaratively set macOS Dock entries via dockutil.
# Only resets the Dock when entries differ from the desired state.
# Adapted from: https://github.com/dustinlyons/nixos-config/blob/main/modules/darwin/dock/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.local.dock;
  inherit (pkgs) stdenv dockutil;
in {
  options = {
    local = {
      dock = {
        enable = lib.mkOption {
          description = "Enable dock";
          default = stdenv.isDarwin;
        };

        entries = lib.mkOption {
          description = "Entries on the Dock";
          type = lib.types.listOf (lib.types.submodule {
            options = {
              path = lib.mkOption {type = lib.types.str;};
              section = lib.mkOption {
                type = lib.types.str;
                default = "apps";
              };
              options = lib.mkOption {
                type = lib.types.str;
                default = "";
              };
            };
          });
          readOnly = true;
        };

        username = lib.mkOption {
          description = "Username to apply the dock settings to";
          type = lib.types.str;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      normalize = path:
        if lib.hasSuffix ".app" path
        then path + "/"
        else path;
      entryURI = path:
        "file://"
        + (
          builtins.replaceStrings
          [" " "!" "\"" "#" "$" "%" "&" "'" "(" ")"]
          ["%20" "%21" "%22" "%23" "%24" "%25" "%26" "%27" "%28" "%29"]
          (normalize path)
        );
      wantURIs = lib.concatMapStrings (entry: "${entryURI entry.path}\n") cfg.entries;
      createEntries =
        lib.concatMapStrings
        (
          entry: "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n"
        )
        cfg.entries;
    in {
      system = {
        activationScripts = {
          postActivation = {
            text = ''
                echo >&2 "Setting up the Dock for ${cfg.username}..."
                su ${cfg.username} -s /bin/sh <<'USERBLOCK'
              haveURIs="$(${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
              if ! diff -wu <(echo -n "$haveURIs") <(echo -n '${wantURIs}') >&2 ; then
                echo >&2 "Resetting Dock."
                ${dockutil}/bin/dockutil --no-restart --remove all
                ${createEntries}
                killall Dock
              else
                echo >&2 "Dock setup complete."
              fi
              USERBLOCK
            '';
          };
        };
      };
    }
  );
}
