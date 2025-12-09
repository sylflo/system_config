{ lib, inputs, config, pkgs, ... }:
{

  home.username = "sylflo";
  home.homeDirectory = "/home/sylflo";

  home.packages = with pkgs; [
    # Fonts
    hack-font
    fira-code
    # Development tools
    neovim
    ansible
    python3
    parallel
    poetry
    rustup
    inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Personal applications
    mpv
    anki-bin
    spotify
    google-chrome
    plex-desktop
    eog
    # Wayland desktop tools
    rofi
    swww
    waypaper
    grim
    slurp
    wl-clipboard
    socat
    # Other desktop tools
    ddcutil
    # User utilities
    playerctl
    wireguard-tools
    ffmpeg
    vlc
    pulseaudio
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    plugins = [
      inputs.hyprland-virtual-desktops.packages.${pkgs.stdenv.hostPlatform.system}.virtual-desktops
    ];
    extraConfig = ''
      source = ~/.config/hypr/hyprland-source.conf

      # Wallpaper daemon
      exec-once = swww init
      exec-once = ~/.local/bin/workspace-wallpaper.sh

      plugin {
        virtual-desktops {
          names = 1:coding, 2:internet, 3:mail and chats
          cycleworkspaces = 1
          rememberlayout = size
          notifyinit = 0
          verbose_logging = 0
        }
     }
    '';
  };

  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      source = ~/.config/hypr/hyprlock-source.conf
    '';
  };

  home.file = {
    # Hyprland dotfiles management
    ".config/hypr/hyprland-source.conf".source = ../../dotfiles/hypr/hyprland-source.conf;
    ".config/hypr/hyprlock-source.conf".source = ../../dotfiles/hypr/hyprlock-source.conf;

    # Rofi configuration
    ".config/rofi/config.rasi".source = ../../dotfiles/rofi/config.rasi;
    ".config/rofi/themes/shinkai.rasi".source = ../../dotfiles/rofi/themes/shinkai.rasi;

    # Alacritty configuration with theme switching support
    ".config/alacritty/alacritty.toml".source = ../../dotfiles/alacritty/alacritty-base.toml;
    ".config/alacritty/themes/shinkai-dark.toml".source = ../../dotfiles/alacritty/themes/shinkai-dark.toml;
    ".config/alacritty/themes/shinkai-light.toml".source = ../../dotfiles/alacritty/themes/shinkai-light.toml;
    ".config/alacritty/themes/shinkai-current.toml".source = ../../dotfiles/alacritty/themes/shinkai-dark.toml;  # Default to dark

    # Scripts
    ".local/bin/start_steam_sunshine.sh".source = ../../dotfiles/scripts/start_steam_sunshine.sh;
    ".local/bin/shutdown_steam_sunshine.sh".source = ../../dotfiles/scripts/shutdown_steam_sunshine.sh;
    ".local/bin/workspace-wallpaper.sh" = {
      source = ../../dotfiles/scripts/workspace-wallpaper.sh;
      executable = true;
    };
    ".local/bin/alacritty-theme-switch.sh" = {
      source = ../../dotfiles/scripts/alacritty-theme-switch.sh;
      executable = true;
    };

    # Wallpapers
    "Pictures/Wallpapers/Themes/Makoto_Shinkai" = {
      source = ../../dotfiles/wallpapers;
      recursive = true;
    };
  };

  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      control-center-margin-top = 60;
      control-center-margin-right = 24;
      notification-icon-size = 56;
      markup = true;
      # --- auto-close timeouts (milliseconds) ---
      timeout          = 5;  # default if urgency not specified
      timeout-low      = 5;  # low urgency
      timeout-normal   = 5;  # normal urgency
      timeout-critical = 0;     # 0 = never auto-close (keep critical)
    };
    #style = ../../dotfiles/swaync-style.css;
  };

  services.hypridle = {
    enable = false;
    settings = {
      general = {
        lock_cmd = "hyprlock";
        before_sleep_cmd = "hyprlock";
        #after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = true;
      };
      listener = [
        {
          timeout = 3600;
          on-timeout = "hyprlock";
        }
        {
          timeout = 3610;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        #{
        #  timeout = 20;
        #  on-timeout = "systemctl suspend";
        #}
      ];
    };
  };

  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value= true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = false;
      DisableAccounts = false;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
      DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
      SearchBar = "unified"; # alternative: "separate"
      Preferences = {
        "cookiebanners.service.mode.privateBrowsing" = 2; # Block cookie banners in private browsing
        "cookiebanners.service.mode" = 2; # Block cookie banners
        "privacy.donottrackheader.enabled" = true;
        "privacy.fingerprintingProtection" = true;
        "privacy.resistFingerprinting" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
      };
      ExtensionSettings = {
        "*".installation_mode = "blocked";
        # uBlock Origin:
       "uBlock0@raymondhill.net" = {
         install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
         installation_mode = "force_installed";
       };
       # Bitwarden
       "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
         install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
         installation_mode = "force_installed";
         #default_area = "navbar";
         default_area = "menupanel";
       };
       # MAL-Sync
       "{c84d89d9-a826-4015-957b-affebd9eb603}" = {
         install_url = "https://addons.mozilla.org/fr/firefox/addon/mal-sync/";
         installation_mode = "force_installed";
         default_area = "menupanel";
       };
       "{e2e52b5d-337a-4693-abde-a096277d3710}" = {
         install_url = "https://addons.mozilla.org/en-US/firefox/addon/leetcode-themes/latest.xpi";
         installation_mode = "force_installed";
         default_area = "menupanel";
       };
       
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "sylflo";
      user.email = "git@sylvain-chateau.com";
      pull.rebase = true;
    };
  };


  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
    ];
  };

  # Alacritty terminal - Makoto Shinkai aesthetic with theme switching
  programs.alacritty = {
    enable = true;
    # Config is managed via TOML files for easier theme switching
  };

  # Enable Zsh as the shell
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true; # Install and manage Oh My Zsh
      plugins = [ "git" "z" "vi-mode" ]; # Add desired plugins
      theme = "robbyrussell"; # Clean, consistent theme (Shinkai-friendly colors)
    };

    # Custom zsh configuration
    initContent = ''
      # Custom .zshrc configuration
      export PATH=$HOME/.local/bin:$HOME/.config/elenapan/bin:$PATH

      # Use a widely supported terminal type to avoid "Error opening terminal: alacritty" on SSH
      export TERM=xterm-256color

      # Enable aliases
      alias ll='ls -la'
      alias gs='git status'

      # LS_COLORS for better directory/file colors with dark Shinkai theme
      export LS_COLORS='di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34'

      # Auto-start Hyprland on TTY1
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
        exec Hyprland
      fi

      export ANDROID_HOME="$HOME/Android/Sdk"
      export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
      export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"
    '';
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
