# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.extraHosts = ''
    127.0.0.1 firestore.docker
    127.0.0.1 auth.docker
    127.0.0.1 emulator-ui.docker
    127.0.0.1 pubsub.docker
    127.0.0.1 api-backend.docker
    127.0.0.1 api-console.docker
    127.0.0.1 building-app.docker
    127.0.0.1 bigquery.docker
    127.0.0.1 mpc-app.docker
    127.0.0.1 gateway-app.docker
    127.0.0.1 report-energy-app.docker
    127.0.0.1 general-equipment-app.docker
    127.0.0.1 frontend.docker
  '';

  networking.hostName = "work-laptop";
}
