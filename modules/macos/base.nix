{
  pkgs,
  vars,
  ...
}: {
  imports = [
    ./_dock.nix
    ./_packages.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nix;
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
    };
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "@admin"
      ];
    };
  };

  # inspo: https://github.com/nix-darwin/nix-darwin/issues/1339
  ids.gids.nixbld = 350;

  programs.zsh.enable = true;
  programs.fish.enable = true;

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };

  users.users.${vars.userName} = {
    home = "/Users/${vars.userName}";
    shell = pkgs.bash;
  };

  system = {
    primaryUser = vars.userName;
    startup.chime = false;

    defaults = {
      CustomUserPreferences = {
        NSGlobalDomain = {
          AppleIconAppearanceTheme = "RegularDark";
        };
      };

      LaunchServices.LSQuarantine = true; # Whether to enable quarantine for downloaded applications. The default is true.

      NSGlobalDomain = {
        AppleEnableMouseSwipeNavigateWithScrolls = true;
        AppleEnableSwipeNavigateWithScrolls = true;
        AppleICUForce24HourTime = true;
        # AppleIconAppearanceTheme = "RegularDark"; # To set to default mode, set this to null and you’ll need to manually run defaults delete -g AppleIconAppearanceTheme.
        AppleInterfaceStyle = "Dark"; # To set to light mode, set this to null and you’ll need to manually run defaults delete -g AppleInterfaceStyle.
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "WhenScrolling";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = true;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDisableAutomaticTermination = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSWindowShouldDragOnGesture = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        _HIHideMenuBar = true;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.trackpad.forceClick" = true;
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      WindowManager = {
        StageManagerHideWidgets = true;
        StandardHideWidgets = true;
      };

      controlcenter.BatteryShowPercentage = true;

      dock = {
        autohide = true;
        largesize = 64;
        magnification = true;
        minimize-to-application = true;
        mru-spaces = false;
        orientation = "bottom";
        show-recents = false;
        tilesize = 48;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
        _FXSortFoldersFirstOnDesktop = true;
      };

      loginwindow = {
        GuestEnabled = false;
        LoginwindowText = "If lost, contact ${vars.userEmail}";
      };

      magicmouse.MouseButtonMode = "TwoButton";

      menuExtraClock = {
        Show24Hour = true;
        ShowAMPM = false;
        ShowDate = 0;
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
      };

      screencapture = {
        disable-shadow = true;
        include-date = true;
        type = "png";
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  local = {
    dock = {
      enable = true;
      username = vars.userName;
      entries = [
        {path = "/Applications/Zen.app";}
        {path = "/Applications/Ghostty.app";}
        {path = "/Applications/Emacs.app";}
        {path = "/Applications/Discord.app";}
        {path = "/System/Applications/Messages.app";}
        {path = "/System/Applications/Reminders.app";}
        {path = "/System/Applications/Notes.app";}
        {path = "/Applications/Infuse.app";}
        {path = "/System/Applications/System Settings.app";}
      ];
    };
  };

  system.stateVersion = 4;
}
