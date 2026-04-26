{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
      };
      cpu = {
        governor = "performance";
        governor_game = "performance";
      };
      # No gpu block: nv_powermizer_mode uses nvidia-settings via NV-CONTROL,
      # which is unavailable with hardware.nvidia.open = true (open kernel module).
      # The call would silently fail. Ampere defaults to full performance under load.
    };
  };

  # gamescope is available for per-game use (Steam launch option: gamescope -- %command%)
  # but NOT used for Big Picture streaming — running it nested under Hyprland
  # (compositor-inside-compositor) caused shaking/judder artifacts. Sunshine
  # captures the Hyprland display directly; Steam Big Picture runs as a plain
  # Wayland window via start_steam_sunshine.sh.
  programs.gamescope = {
    enable = true;
    # capSysNice = true breaks Steam's bubblewrap sandbox (bwrap rejects
    # processes with unexpected capabilities), preventing games from launching
    # inside gamescope.
    capSysNice = false;
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
    };
  };

  # realtime scheduling for gamemode + pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    };

  # locked memory + realtime priority limits for audio/gaming
  security.pam.loginLimits = [
    { domain = "@audio"; type = "-"; item = "memlock"; value = "unlimited"; }
    { domain = "@audio"; type = "-"; item = "rtprio"; value = "99"; }
    { domain = "@audio"; type = "-"; item = "nice"; value = "-19"; }
  ];

  users.users.sylflo.extraGroups = [ "audio" ];
}
