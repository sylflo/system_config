{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-virtual-desktops = {
      url = "github:levnikmyskin/hyprland-virtual-desktops?ref=v2.2.8";
      inputs.nixpkgs.follows = "nixpkgs";
    };
   };

  outputs = { self, nixpkgs, home-manager, hyprland-virtual-desktops, ... }@inputs:
    let
      mkSystem = { hostname, homeConfig }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./common/configuration.nix
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.sylflo = import homeConfig;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkSystem {
          hostname = "desktop";
          homeConfig = ./hosts/desktop/home.nix;
        };
        personal-laptop = mkSystem {
          hostname = "personal-laptop";
          homeConfig = ./common/home.nix;
        };
        work-laptop = mkSystem {
          hostname = "work-laptop";
          homeConfig = ./hosts/work-laptop/home.nix;
        };
      };
  };
}
