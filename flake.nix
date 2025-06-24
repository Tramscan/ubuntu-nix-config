{
  description = "My Ubuntu Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-mesa-24-2-7 = {
      url = "github:NixOS/nixpkgs/459a925026a28f5a762d648108c4d21068d080e3";
      flake = false;
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gl-host = {
      url = "github:numtide/nix-gl-host";
    };
  };
  outputs = { self, nixpkgs, home-manager, nixvim, nixgl, nixpkgs-mesa-24-2-7, nix-gl-host, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages.${system}.nix-gl-host = nix-gl-host.defaultPackage.${system.nix-gl-host};

    homeConfigurations = {
      nick = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager/home.nix
          nixvim.homeManagerModules.nixvim
        ];
        extraSpecialArgs = {
          inherit inputs nixgl;
        };
      };
    };
  };
}


