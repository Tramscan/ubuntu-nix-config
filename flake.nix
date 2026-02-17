{ description = "My Ubuntu Nix - with auto NVIDIA version detection";

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
        config.allowUnfreePredicate = (_: true);
      };

      # Function to find system-specific config
      # Looks for: ~/.config/nix/systems/<name>.nix
      mkHomeConfig = { username ? "nick", extraModules ? [] }: 
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home-manager/home.nix
            nixvim.homeManagerModules.nixvim
          ] ++ extraModules;
          extraSpecialArgs = { inherit inputs nixgl; };
        };

    in {
      packages.${system}.nix-gl-host = nix-gl-host.defaultPackage.${system.nix-gl-host};

      homeConfigurations = {
        # Default configuration (desktop/NVIDIA)
        nick = mkHomeConfig { username = "nick"; };

        # Laptop configuration (example of per-system configs)
        # To use: home-manager switch --flake .#laptop
        laptop = mkHomeConfig {
          extraModules = [
            ({ config.systemConfig.nixGLVariant = "none"; })
          ];
        };

        # Minimal config (no GPU)
        minimal = mkHomeConfig {
          extraModules = [
            ({ 
              config.systemConfig.nixGLVariant = "none";
              config.systemConfig.systemType = "minimal";
              config.nvidiaManagement.enableAutoDetection = false;
            })
          ];
        };
      };

      # Script to run onboarding
      apps.${system}.onboard = {
        type = "app";
        program = "${self}/scripts/onboard.sh";
      };
    };
}