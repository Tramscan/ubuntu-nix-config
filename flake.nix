{
  description = "My Ubuntu Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixgl";
    };
  };
  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    nixgl,
    ...
  }: let
    # system = "aarch64-linux"; If you are running on ARM powered computer
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ nixgl.overlay ];
    };
  in {
    homeConfigurations = {
      nick = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager/home.nix
	  nixvim.homeManagerModules.nixvim 
        ];
      };
    };

  };
}


