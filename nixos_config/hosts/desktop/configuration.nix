# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # NVIDIA-specific packages
  environment.systemPackages = with pkgs; [
    nvidia-modprobe
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  powerManagement.cpuFreqGovernor = "performance";

  networking.hostName = "desktop"; # Define your hostname.
  networking.interfaces.eno1.wakeOnLan.enable = true;
  boot.blacklistedKernelModules = [ "rtl8192ee" ];

  #############
  ## Nvidia ##
  ###########

  boot.initrd.kernelModules = [ "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "i2c-dev" ];

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    displayManager.startx.enable = true;
  };

  services.getty.autologinUser = "sylflo";

  # Enable hardware acceleration
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Required for the RTX 3060 (Ampere) — stable on this generation.
    open = true;

    # Enable the Nvidia settings menu, accessible via `nvidia-settings`.
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  # Sudo configuration
  security.sudo = {
    enable = true;             # enable sudo
    wheelNeedsPassword = true; # require password for wheel by default
    extraRules = [
      {
        users = [ "sylflo" ];
        commands = [
          {
            command = "/etc/profiles/per-user/sylflo/bin/ddcutil";
          }
        ];
      }
    ];
  };


  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = false; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = false; # Open ports in the firewall for Steam Local Network Game Transfers
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
      };
      # GPU block is intentionally minimal: we run hardware.nvidia.open = true
      # (open kernel module), which doesn't expose GPUGraphicsClockOffset via
      # nvidia-settings. Setting apply_gpu_optimisations = "accept-responsibility"
      # makes gamemode try to apply clock offsets and fail noisily. We keep
      # nv_powermizer_mode = 1 (Prefer Maximum Performance) since that one
      # attribute is supported by the open module.
      gpu = {
        nv_powermizer_mode = 1;
      };
    };
  };
  programs.gamescope = {
    enable = true;
    capSysNice = false;
    # capSysNice = true breaks Steam's bubblewrap sandbox (bwrap rejects
    # processes with unexpected capabilities), preventing games from launching
    # inside gamescope.
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

  # Enable PipeWire with JACK support for low-latency audio recording
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Increase locked memory limit for audio production
  security.pam.loginLimits = [
    { domain = "@audio"; type = "-"; item = "memlock"; value = "unlimited"; }
    { domain = "@audio"; type = "-"; item = "rtprio"; value = "99"; }
    { domain = "@audio"; type = "-"; item = "nice"; value = "-19"; }
  ];

  # Add user to audio group
  users.users.sylflo.extraGroups = [ "audio" ];

  # Enable SSH server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Open SSH port in firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

 services.ollama = {
  enable = true;
  acceleration = "cuda";
 };

}
