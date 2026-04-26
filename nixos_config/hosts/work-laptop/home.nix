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

  # Work-laptop specific packages
  home.packages = with pkgs; [
    google-cloud-sdk
  ];


}
