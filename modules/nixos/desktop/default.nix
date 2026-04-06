# Desktop modules — shared desktop services, hardware, and compositor(s).
# desktop.enable gates shared services (accounts-daemon, printing, fonts, etc.).
# desktop.shell selects a desktop shell (default: Noctalia); when set, shell-owned
# bar/notification/lock/wallpaper programs in the HM niri module are skipped.
# swayidle remains session-side because lid-close locking still needs a user
# session hook before suspend. Rofi stays available on Mod+D across shell
# choices.
# Hardware features and compositors are individually gated behind their own enable flags.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  gfxCfg = homelabCfg.hardware.graphics;
  isIntel = gfxCfg.driver == "intel";
  isAmd = gfxCfg.driver == "amd";
in {
  imports = [
    ./_greetd.nix
    ./_niri.nix
    ./_noctalia.nix
  ];

  options = {
    homelab = {
      desktop = {
        enable = lib.mkEnableOption "desktop environment (shared services, login manager)";

        shell = lib.mkOption {
          default = "noctalia";
          type = lib.types.enum [
            "none"
            "noctalia"
          ];
          description = "Desktop shell providing bar, notifications, lock screen, wallpaper, and idle handling. When set, individual replacements (waybar, swaync, swaylock, swaybg, udiskie) are not installed. swayidle remains available for session-side before-sleep locking. Rofi remains available as the launcher on Mod+D.";
        };
      };

      hardware = {
        audio = {
          enable = lib.mkEnableOption "audio support";
        };

        bluetooth = {
          enable = lib.mkEnableOption "bluetooth support";
        };

        fingerprint = {
          enable = lib.mkEnableOption "fingerprint reader support (fprintd)";
        };

        graphics = {
          enable = lib.mkEnableOption "graphics support";

          driver = lib.mkOption {
            default = "intel";
            type = lib.types.enum [
              "intel"
              "amd"
            ];
            description = "GPU driver family — determines which VA-API/VDPAU packages to install.";
          };
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.desktop.enable {
    # System-wide desktop glue that is not owned by a single service module.
    # Today this is only the Bitwarden polkit action used for "system auth"
    # unlocks. Keep it gated to fingerprint-capable desktops because that is
    # the only path in this repo that currently relies on the action.
    environment.systemPackages = lib.optionals homelabCfg.hardware.fingerprint.enable [
      # Install the policy file via the Nix store so polkit sees the
      # com.bitwarden.Bitwarden.unlock action during desktop sessions.
      (pkgs.writeTextDir "share/polkit-1/actions/com.bitwarden.Bitwarden.policy" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE policyconfig PUBLIC
         "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
         "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
        <policyconfig>
          <action id="com.bitwarden.Bitwarden.unlock">
            <description>Unlock Bitwarden</description>
            <message>Authenticate to unlock Bitwarden</message>
            <defaults>
              <allow_any>auth_self</allow_any>
              <allow_inactive>auth_self</allow_inactive>
              <allow_active>auth_self</allow_active>
            </defaults>
          </action>
        </policyconfig>
      '')
    ];

    services = {
      logind = {
        # Laptop lid handling is owned by logind, not the compositor. Suspend on
        # lid close whether on battery or AC; keep docked systems awake so an
        # external monitor/keyboard setup can continue running with the lid shut.
        # The matching lock happens from the user session via swayidle so the
        # shell/compositor can still paint the lock screen before suspend.
        settings = {
          Login = {
            HandleLidSwitch = "suspend";
            HandleLidSwitchExternalPower = "suspend";
            HandleLidSwitchDocked = "ignore";
          };
        };
      };
    };

    hardware = {
      bluetooth = lib.mkIf homelabCfg.hardware.bluetooth.enable {
        enable = true;
        powerOnBoot = true;
      };

      # GPU acceleration (mesa)
      graphics = lib.mkIf gfxCfg.enable {
        enable = true;

        extraPackages = with pkgs;
          if isIntel
          then [
            intel-media-driver # iHD — hardware video decode/encode (Broadwell+)
            intel-vaapi-driver # i965 — fallback for older Intel iGPUs
            intel-compute-runtime # OpenCL runtime (NEO)
            libva-vdpau-driver # VDPAU compatibility layer over VA-API
            libvdpau-va-gl # VDPAU fallback via OpenGL
          ]
          else [
            # AMD uses mesa's built-in RADV/radeonsi — no extra VA-API driver needed
            libvdpau-va-gl # VDPAU fallback via OpenGL
          ];
      };

      # AMD GPU kernel driver
      amdgpu = lib.mkIf (gfxCfg.enable && isAmd) {
        initrd = {
          enable = true;
        };
      };
    };

    security = {
      # RealtimeKit gives PipeWire realtime scheduling priority
      rtkit = lib.mkIf homelabCfg.hardware.audio.enable {
        enable = true;
      };
    };

    services = {
      # PipeWire replaces PulseAudio + ALSA with a single unified daemon
      pipewire = lib.mkIf homelabCfg.hardware.audio.enable {
        enable = true;

        alsa = {
          enable = true;
          # 32-bit compatibility for Wine/Steam
          support32Bit = true;
        };

        pulse = {
          enable = true;
        };
      };

      # Fingerprint authentication daemon
      fprintd = lib.mkIf homelabCfg.hardware.fingerprint.enable {
        enable = true;
      };

      # GNOME Keyring — credential storage (Element, Discord tokens, etc.),
      # auto-unlocked via PAM on password login (fingerprint login cannot unlock it)
      gnome = {
        gnome-keyring = {
          enable = true;
        };
      };

      accounts-daemon = {
        enable = true;
      };

      # ananicy-cpp — auto-nice daemon that prioritises interactive desktop apps
      # (compositor, browser, terminal) and de-prioritises background work
      # (builds, indexers). Uses CachyOS community rules as a base; Zen Beta
      # is added manually because upstream rules only cover "zen" / "zen-bin".
      ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
        extraRules = [
          {
            name = "zen-beta";
            type = "Doc-View";
          }
        ];
      };

      power-profiles-daemon = {
        enable = true;
      };

      printing = {
        enable = true;
      };

      # Battery/power monitoring
      upower = {
        enable = true;
      };
    };

    boot = {
      # Zen kernel — BORE scheduler for lower interactive latency, 1000Hz tick,
      # and optimized preemption. ZFS 2.3.x is compatible with the Zen kernel.
      # If issues arise, select an older generation from GRUB to revert.
      kernelPackages = pkgs.linuxPackages_zen;

      # Desktop VM / scheduler tuning (inspired by CachyOS defaults).
      # Absolute byte dirty limits give predictable write-back regardless of RAM
      # size; zram-aware swappiness and single-page reads suit compressed swap.
      kernel = {
        sysctl = {
          # zram-optimized: high swappiness prefers compressing to zram over
          # evicting file cache; single-page reads (page-cluster=0) suit zram
          # since there is no rotational seek penalty to amortise.
          "vm.swappiness" = 150;
          "vm.page-cluster" = 0;

          # Predictable write-back: flush at 64 MB background / 256 MB hard cap
          "vm.dirty_background_bytes" = 67108864;
          "vm.dirty_bytes" = 268435456;

          # Keep filesystem metadata cached aggressively
          "vm.vfs_cache_pressure" = 50;

          # Avoid background compaction latency spikes
          "vm.compaction_proactiveness" = 0;

          # Larger free-memory reserve to prevent allocation stalls
          "vm.min_free_kbytes" = 67584;

          # Disable NMI watchdog (saves power, reduces interrupts)
          "kernel.nmi_watchdog" = 0;

          # Disable split-lock mitigation (avoids performance penalty)
          "kernel.split_lock_mitigate" = 0;
        };
      };
    };

    # Wayland session — toolkit hints and VA-API driver selection
    environment = {
      sessionVariables = lib.mkMerge [
        {
          NIXOS_OZONE_WL = "1"; # Electron apps: use native Wayland
          MOZ_ENABLE_WAYLAND = "1"; # Firefox/Zen: use native Wayland
        }
        (lib.mkIf gfxCfg.enable {
          # iHD = Broadwell+ Intel (UHD 620, etc.), radeonsi = AMD (RDNA, etc.)
          LIBVA_DRIVER_NAME =
            if isIntel
            then "iHD"
            else "radeonsi";
        })
      ];
    };

    fonts = {
      # Font rendering — anti-aliasing, hinting, and subpixel rendering for
      # crisp text on LCD panels. autohint is off so fonts with good built-in
      # hints (JetBrains Mono, Montserrat) render as intended.
      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          autohint = false;
          style = "slight";
        };
        subpixel = {
          # RGB matches standard LCD subpixel layout (including ThinkPad panels)
          rgba = "rgb";
          lcdfilter = "default";
        };
      };

      packages = with pkgs; [
        # Sans-serif / serif
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        # Emoji
        noto-fonts-color-emoji
      ];
    };
  };
}
