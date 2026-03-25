# Starship — cross-shell prompt with Catppuccin-inspired colour segments.
# Shows: OS icon, hostname (SSH only), directory, git, language versions,
# k8s context, docker, conda, time, and command duration.
{
  homelabCfg,
  lib,
  ...
}: let
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;
in {
  programs = {
    starship = {
      inherit (homelabCfg.programs.starship) enable;
      enableBashIntegration = true;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;

      settings = {
        add_newline = false;

        # Catppuccin Mocha palette is hardcoded here because Starship uses named
        # palette references in format strings (e.g. "fg:mauve"). Stylix provides
        # base16 colors (base00-base0F) which don't map to Catppuccin's named
        # colors, so we maintain the full palette inline.
        palette = "catppuccin_mocha";

        palettes = {
          catppuccin_mocha = {
            rosewater = "#f5e0dc";
            flamingo = "#f2cdcd";
            pink = "#f5c2e7";
            mauve = "#cba6f7";
            red = "#f38ba8";
            maroon = "#eba0ac";
            peach = "#fab387";
            yellow = "#f9e2af";
            green = "#a6e3a1";
            teal = "#94e2d5";
            sky = "#89dceb";
            sapphire = "#74c7ec";
            blue = "#89b4fa";
            lavender = "#b4befe";
            text = "#cdd6f4";
            subtext1 = "#bac2de";
            subtext0 = "#a6adc8";
            overlay2 = "#9399b2";
            overlay1 = "#7f849c";
            overlay0 = "#6c7086";
            surface2 = "#585b70";
            surface1 = "#45475a";
            surface0 = "#313244";
            base = "#1e1e2e";
            mantle = "#181825";
            crust = "#11111b";
          };
        };

        format = lib.concatStrings [
          "[](red)"
          "$os"
          "$hostname"
          "[](bg:peach fg:red)"
          "$directory"
          "[](bg:yellow fg:peach)"
          "[](fg:yellow bg:green)"
          "$c"
          "$rust"
          "$golang"
          "$nix_shell"
          "$nodejs"
          "$php"
          "$java"
          "$kotlin"
          "$haskell"
          "$python"
          "$terraform"
          "[](fg:green bg:sapphire)"
          "$conda"
          "[](fg:sapphire bg:lavender)"
          "$time"
          "[ ](fg:lavender)"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];

        os = {
          disabled = false;
          style = "bg:red fg:crust";

          symbols = {
            Windows = " ";
            Ubuntu = "󰕈 ";
            SUSE = " ";
            Raspbian = "󰐿 ";
            Mint = "󰣭 ";
            Macos = "󰀵 ";
            Manjaro = " ";
            Linux = "󰌽 ";
            Gentoo = "󰣨 ";
            Fedora = "󰣛 ";
            Alpine = " ";
            Amazon = " ";
            Android = " ";
            Arch = "󰣇 ";
            Artix = "󰣇 ";
            CentOS = " ";
            Debian = "󰣚 ";
            Redhat = "󱄛 ";
            RedHatEnterprise = "󱄛 ";
            NixOS = " ";
          };
        };

        username = {
          show_always = true;
          style_user = "bg:red fg:crust";
          style_root = "bg:red fg:crust";
          format = "[ $user]($style)";
        };

        hostname = {
          ssh_only = true;
          ssh_symbol = "󰢹";
          style = "bg:red fg:crust";
          format = "[[ $ssh_symbol in $hostname](fg:crust bg:red)]($style)";
        };

        directory = {
          style = "bg:peach fg:crust";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
        };

        gcloud = {
          symbol = " ";
          format = "[[ $symbol$project ](fg:crust bg:green)]($style)";
          style = "bg:green";
        };

        git_branch = {
          symbol = "";
          style = "bg:yellow";
          format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)";
        };

        git_status = {
          style = "bg:yellow";
          format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)";
        };

        kubernetes = {
          disabled = false;
          symbol = "󱃾 ";
          style = "fg:crust bg:green";
          format = "[ $symbol$context ]($style)";
        };

        nodejs = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        c = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        nix_shell = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        terraform = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        rust = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        golang = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        php = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        java = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        kotlin = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        haskell = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };

        python = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version)(\(#$virtualenv\)) ](fg:crust bg:green)]($style)";
        };

        docker_context = {
          symbol = " ";
          style = "bg:sapphire";
          format = "[[ $symbol( $context) ](fg:crust bg:sapphire)]($style)";
        };

        conda = {
          symbol = "  ";
          style = "fg:crust bg:sapphire";
          format = "[$symbol$environment ]($style)";
          ignore_base = false;
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:lavender";
          format = "[[  $time ](fg:crust bg:lavender)]($style)";
        };

        line_break = {
          disabled = false;
        };

        character = {
          disabled = false;
          success_symbol = "[❯](bold fg:green)";
          error_symbol = "[❯](bold fg:red)";
          vimcmd_symbol = "[❮](bold fg:green)";
          vimcmd_replace_one_symbol = "[❮](bold fg:lavender)";
          vimcmd_replace_symbol = "[❮](bold fg:lavender)";
          vimcmd_visual_symbol = "[❮](bold fg:yellow)";
        };

        cmd_duration = {
          show_milliseconds = true;
          format = " in $duration ";
          style = "bg:lavender";
          disabled = false;
          show_notifications = true;
          min_time_to_notify = 45000;
        };
      };
    };
  };
}
