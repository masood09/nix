# Option tree for the arr media stack. One `homelab.services.arr.enable` switch, matching
# every other service in this repo — see default.nix for how these translate into the
# nixflix flake input's own (foreign) option namespace, which is an implementation detail.
{lib, ...}: {
  options = {
    homelab = {
      services = {
        arr = {
          enable = lib.mkEnableOption "Arr media stack (Jellyfin/Sonarr/Radarr/Prowlarr/SABnzbd/Seerr/Recyclarr)";

          mediaDir = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/tank/media/library";
            description = "TRaSH-guide media library root.";
          };

          downloadsDir = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/tank/media/downloads";
            description = ''
              TRaSH-guide downloads root. Must resolve to the same filesystem/dataset as
              mediaDir so completed downloads can be atomically moved (hardlinked/renamed)
              into the library instead of copied.
            '';
          };

          stateDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/arr";
            description = "Per-app config/state root; each app lands at \${stateDir}/<app>.";
          };

          jellyfin = {
            enable = lib.mkEnableOption "Jellyfin";

            hardwareAcceleration = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable VAAPI/QuickSync hardware transcoding (requires an Intel iGPU with /dev/dri present).";
            };
          };

          sonarr.enable = lib.mkEnableOption "Sonarr";
          radarr.enable = lib.mkEnableOption "Radarr";
          prowlarr.enable = lib.mkEnableOption "Prowlarr";
          sabnzbd.enable = lib.mkEnableOption "SABnzbd";
          seerr.enable = lib.mkEnableOption "Seerr (https://seerr.dev — media request/discovery manager for Jellyfin/Plex/Emby)";

          recyclarr = {
            enable = lib.mkEnableOption "Recyclarr TRaSH-guide quality-profile/custom-format sync";

            radarrQuality = lib.mkOption {
              type = lib.types.enum ["4K" "1080p"];
              default = "4K";
              description = "Recyclarr's built-in Radarr quality-profile preset.";
            };

            sonarrQuality = lib.mkOption {
              type = lib.types.enum ["4K" "1080p"];
              default = "4K";
              description = "Recyclarr's built-in Sonarr quality-profile preset.";
            };
          };

          usenetProviders = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [];
            example = [
              {
                name = "provider-name";
                host = "news.provider.example";
                port = 563;
                ssl = true;
                connections = 20;
                retention = 3000;
                username._secret = "/run/secrets/arr/usenet-provider-username";
                password._secret = "/run/secrets/arr/usenet-provider-password";
              }
            ];
            description = "SABnzbd server definitions — passed straight through to nixflix.usenetClients.sabnzbd.settings.servers.";
          };

          indexers = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [];
            example = [
              {
                name = "indexer-name";
                apiKey._secret = "/run/secrets/arr/indexer-name-api-key";
              }
            ];
            description = "Prowlarr indexer definitions — passed straight through to nixflix.prowlarr.config.indexers.";
          };
        };
      };
    };
  };
}
