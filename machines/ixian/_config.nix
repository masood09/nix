# Homelab options — Gamescope Steam machine with a retained SSH admin account.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # The console account is defined once, in _users.nix, which also sets
  # homelab.desktop.gaming.user. It is not homelab.primaryUser: the primary
  # user here is the admin account used for SSH and sudo.
  gamingUser = config.homelab.desktop.gaming.user;
in {
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
              directory = "/home/${gamingUser}";
              user = gamingUser;
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

          # Free the GPU for gaming: stop Strata while the living-room TCL
          # Google TV is on, start it again once the TV has been off for 30 s,
          # and let the guard be the only thing that starts Strata (it drops the
          # unit from multi-user.target, so boot and switch cannot load the
          # model over a running game).
          tvGuard = {
            enable = true;
            address = "tcltv.iot.homelab.mantannest.com:5555";
          };
        };

        # ai.mantannest.com has no public DNS record; Headscale DNS
        # resolves it to ixian's tailnet IP (100.64.0.2) and UniFi local
        # DNS resolves it on the LAN.
        caddy = {
          enable = true;
        };

        # ixian sits inside 10.0.30.0/24, which jumpbox-home advertises as a
        # subnet route. Accepting it would send replies to LAN clients into
        # the tunnel, cutting ixian off from its own LAN. Matches the module
        # default; kept explicit so it isn't flipped without this context.
        tailscale = {
          enable = true;
          acceptRoutes = false;
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

    # Boot straight into Steam Gaming Mode as the console account (gamingUser,
    # whose name is set by homelab.desktop.gaming.user in _users.nix). Jovian's
    # autoStart uses SDDM autologin with relogin, so if Steam or gamescope
    # exits or crashes the session starts again instead of leaving a blank
    # screen.
    jovian = {
      steam = {
        enable = true;
        autoStart = true;
        user = gamingUser;
        # No desktop session on this console: "Switch to Desktop" relaunches
        # Gaming Mode.
        desktopSession = "gamescope-wayland";
      };

      hardware = {
        has = {
          amd = {
            gpu = true;
          };
        };
      };

      steamos = {
        # SteamOS defaults are tuned for the Steam Deck. Its kernel
        # parameters (amd_iommu=off, ttm.pages_min, …) are Deck-specific, and
        # earlyoom would pick off Strata's ~47 GB resident model or a game
        # under memory pressure. Bluetooth, sysctl, zram, CEC, and automount
        # defaults stay on.
        enableDefaultCmdlineConfig = false;
        enableEarlyOOM = false;
      };
    };

    # ixian deliberately runs the release-26.05 Stylix and Home Manager
    # branches on nixos-unstable (Jovian requires unstable), so their release
    # checks would warn on every build.
    home-manager = {
      sharedModules = [
        {
          home = {
            enableNixpkgsReleaseCheck = false;
          };
        }
      ];
    };

    # Stylix release-26.05's kmscon target writes options nixos-unstable has
    # removed (services.kmscon.extraConfig/fonts). ixian runs no kmscon.
    stylix = {
      enableReleaseChecks = false;

      targets = {
        kmscon = {
          enable = false;
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
        # ixian is a trusted single-admin console; the gaming console account
        # (gamingUser) is not in wheel, so passwordless sudo reaches every wheel
        # member, which today means only the admin account (homelab.primaryUser).
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
      # Steam's Deck-mode power policy suspends the PC after an hour without
      # controller input on mains power ("Switching to power state
      # k_ESystemPowerState_Sleep ... active: 3600 < 3600"), which takes
      # Strata, Caddy, SSH, and monitoring down until someone presses the
      # power button (no Wake-on-LAN). ixian is also a server, so refuse every
      # sleep state: Steam's suspend request fails and the session stays up.
      # Steam's own "suspend when inactive" setting is also set to Never.
      sleep = {
        settings = {
          Sleep = {
            AllowSuspend = "no";
            AllowHibernation = "no";
            AllowHybridSleep = "no";
            AllowSuspendThenHibernate = "no";
          };
        };
      };

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
