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
      # GPU block is intentionally minimal: hardware.nvidia.open = true (open
      # kernel module) does not expose GPUGraphicsClockOffset via nvidia-settings.
      # apply_gpu_optimisations would fail noisily; nv_powermizer_mode = 1 is
      # supported by the open module and forces Prefer Maximum Performance.
      gpu = {
        nv_powermizer_mode = 1;
      };
    };
  };

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
