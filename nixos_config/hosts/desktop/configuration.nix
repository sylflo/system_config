# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ inputs, config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./gaming.nix
  ];

  # NVIDIA-specific packages
  environment.systemPackages = with pkgs; [
    nvidia-modprobe
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  powerManagement.cpuFreqGovernor = "performance";

  networking.hostName = "desktop";
  networking.interfaces.eno1.wakeOnLan.enable = true;
  boot.blacklistedKernelModules = [ "rtl8192ee" ];

  #############
  ## Nvidia ##
  ###########

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "i2c-dev" ];

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    displayManager.startx.enable = true;
  };

  services.getty.autologinUser = "sylflo";

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];

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
