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

  networking.hostName = "desktop"; # Define your hostname.
  networking.interfaces.eno1.wakeOnLan.enable = true;

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

}
