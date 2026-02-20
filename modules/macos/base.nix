{
  config,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./_dock.nix
    ./_networking.nix
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

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };

  users.users.${homelabCfg.primaryUser.userName} = {
    home = "/Users/${homelabCfg.primaryUser.userName}";
    shell = pkgs.bash;
  };

  system = {
    primaryUser = homelabCfg.primaryUser.userName;
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

        # Animations
        NSAutomaticWindowAnimationsEnabled = false;
        NSScrollAnimationEnabled = false;
        NSUseAnimatedFocusRing = false;
        NSWindowResizeTime = 0.001;
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      WindowManager = {
        StageManagerHideWidgets = true;
        StandardHideWidgets = true;
        EnableStandardClickToShowDesktop = false;
      };

      controlcenter.BatteryShowPercentage = true;

      dock = {
        autohide = true;
        expose-animation-duration = 0.001;
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

      universalaccess.reduceMotion = true;
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  system.stateVersion = 4;
}
