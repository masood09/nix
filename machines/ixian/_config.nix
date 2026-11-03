# Homelab options — Gamescope Steam machine with a retained SSH admin account.
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    environment = {
      systemPackages = with pkgs; [
        # AMD GPU/VRAM/process telemetry for Strata and gaming sessions.
        nvtopPackages.amd
        amdgpu_top
      ];

      persistence = {
        "/nix/persist" = {
          directories = [
            {
              directory = "/home/voyageonwheels";
              user = "voyageonwheels";
              group = "users";
              mode = "0700";
            }
          ];
        };
      };
    };

    boot = {
      initrd = {
        luks = {
          devices = {
            # The model disk is unlocked after /nix is mounted, using a key
            # stored on the encrypted root filesystem. This keeps boot to one
            # passphrase while retaining independent LUKS volumes.
            cryptmodels = {
              crypttabExtraOpts = [
                "noauto"
              ];
            };
          };
        };
      };
    };

    homelab = {
      role = "htpc";
      purpose = "Gamescope Steam Gaming and AI Inference PC";
      isRootZFS = false;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "ixian";
      };

      services = {
        # Ships journald logs to Loki and node metrics to Prometheus on
        # heartbeat via the shared alloy/.env endpoints.
        alloy = {
          enable = true;
        };

        # Qwen3.8-Flash-Next IQ3_XXS, 128K context, CPU picture reader, MTP
        # draft layer (module defaults), on 127.0.0.1:8916, served to the LAN
        # by Caddy as ai.mantannest.com.
        strata = {
          enable = true;
        };

        # ai.mantannest.com has no public DNS record; Headscale DNS
        # resolves it to ixian's tailnet IP (100.64.0.2) and UniFi local
        # DNS resolves it on the LAN.
        caddy = {
          enable = true;
        };

        tailscale = {
          enable = true;
        };
      };

      # Install the AMD graphics/compute driver stack for the Steam/Gamescope
      # console without enabling a general-purpose desktop shell.
      hardware = {
        audio = {
          enable = true;
        };

        graphics = {
          enable = true;
          driver = "amd";
        };
      };

      desktop = {
        # ixian is a dedicated Steam/Gamescope console, not a general-purpose
        # desktop. Keep the shared desktop bundle disabled so Flatpak, CUPS,
        # Thunar/GVFS, accounts-daemon, and desktop shells are not installed.
        enable = false;

        gaming = {
          enable = true;
        };

        shell = "none";

        niri = {
          enable = false;
        };
      };
    };

    programs = {
      steam = {
        gamescopeSession = {
          enable = true;
          args = [
            "-e"
          ];
          steamArgs = [
            "-tenfoot"
            "-pipewire-dmabuf"
          ];
        };
      };
    };

    services = {
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse = {
          enable = true;
        };
      };

      greetd = {
        enable = true;
        settings = {
          initial_session = {
            command = "steam-gamescope";
            user = "voyageonwheels";
          };

          default_session = {
            command = "steam-gamescope";
            user = "voyageonwheels";
          };
        };
      };
    };

    security = {
      acme = {
        certs = {
          # The LAN firewall redirects all port-53 traffic on ixian's VLAN to
          # the internal resolvers, which answer NXDOMAIN for the ACME TXT
          # record, so lego's propagation check (direct queries to
          # Cloudflare's nameservers) can never pass from here. Wait a fixed
          # time instead; Let's Encrypt validates from the public internet.
          ${config.networking.domain} = {
            extraLegoFlags = [
              "--dns.propagation-wait=60s"
            ];
          };
        };
      };

      rtkit = {
        enable = true;
      };

      sudo = {
        # ixian is a trusted single-admin console; voyageonwheels is not in
        # wheel, so this applies only to masoodahmed.
        wheelNeedsPassword = lib.mkForce false;
      };
    };

    xdg = {
      # Steam/Gamescope does not need the desktop MIME database. The explicit
      # force resolves the conflict between the Steam session default and the
      # server-style Stylix closure hygiene used by the htpc role.
      icons = {
        enable = lib.mkForce false;
      };
      mime = {
        enable = lib.mkForce false;
      };
      sounds = {
        enable = lib.mkForce false;
      };
    };

    systemd = {
      services = {
        cryptmodels-unlock = {
          description = "Unlock ixian model storage from the root-resident key";
          wantedBy = [
            "srv-models.mount"
          ];
          before = [
            "srv-models.mount"
          ];
          after = [
            "nix.mount"
          ];
          requires = [
            "nix.mount"
          ];
          path = [
            pkgs.cryptsetup
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            if cryptsetup status cryptmodels >/dev/null 2>&1; then
              exit 0
            fi

            cryptsetup open \
              --key-file /nix/secret/ixian-models.key \
              /dev/disk/by-partlabel/disk-models-models \
              cryptmodels
          '';
        };
      };
    };
  };
}
