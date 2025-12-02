{ pkgs, lib, ... }:

{
  imports = [
    ../../common/home.nix
  ];

  # Work-specific git configuration
  programs.git = {
    userName = lib.mkForce "Sylvain Chateau";
    userEmail = lib.mkForce "sylvain.chateau@thermosphr.com";
  };

  # Work-laptop specific scripts
  home.file = {
    ".local/bin/hyprland-monitor-setup.sh".source = ../../../dotfiles/scripts/hyprland-monitor-setup.sh;
  };
}
