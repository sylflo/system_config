# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ inputs, config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./gaming.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  powerManagement.cpuFreqGovernor = "performance";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    # Reduce dirty page writeback thresholds — limits write stall spikes on the
    # single NVMe when the kernel flushes accumulated dirty pages to disk.
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
  };

  networking.hostName = "desktop";
  networking.interfaces.eno1.wakeOnLan.enable = true;
  boot.blacklistedKernelModules = [ "rtl8192ee" ];

  #############
  ## Nvidia ##
  ###########

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "i2c-dev" ];

  # Explicitly preserve VRAM across suspend/resume. powerManagement.enable sets
  # this automatically for the proprietary module; belt-and-suspenders for open.
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    displayManager.startx.enable = true;
  };

  services.getty.autologinUser = "sylflo";

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];

  # Required for nvidia-vaapi-driver with the open kernel module
  environment.sessionVariables.NVD_BACKEND = "direct";

  nixpkgs.config.cudaSupport = true;

  hardware.nvidia = {
    modesetting.enable = true;

    # Saves full VRAM to /tmp on suspend — fixes graphical corruption on wake.
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Open kernel module — stable on Ampere (RTX 3060).
    open = true;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraRules = [
      {
        users = [ "sylflo" ];
        commands = [
          { command = "/etc/profiles/per-user/sylflo/bin/ddcutil"; }
        ];
      }
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };
}
