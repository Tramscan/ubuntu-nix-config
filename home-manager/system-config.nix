# system-config.nix
# System-wide configuration for onboarding and nixGL variant selection
# This module handles:
# - System type (desktop, laptop, minimal)
# - nixGL variant selection (none, default, nvidia, bumblebee, intel)
# - Auto-detection settings for NVIDIA drivers

{ config, lib, pkgs, nixgl, ... }:

let
  cfg = config.systemConfig;

  # Available nixGL variants
  nixGLVariants = {
    none = {
      name = "none";
      package = null;
      binary = null;
      description = "No nixGL wrapper (use system OpenGL)";
    };
    default = {
      name = "default";
      package = nixgl.packages.${pkgs.system}.nixGLDefault;
      binary = "nixGLDefault";
      description = "Auto-detect GPU and use appropriate wrapper";
    };
    nvidia = {
      name = "nvidia";
      package = nixgl.packages.${pkgs.system}.nixGLNvidia;
      binary = "nixGLNvidia";
      description = "NVIDIA GPU with proprietary drivers (versioned)";
    };
    bumblebee = {
      name = "bumblebee";
      package = nixgl.packages.${pkgs.system}.nixGLNvidiaBumblebee;
      binary = "nixGLNvidiaBumblebee";
      description = "NVIDIA Optimus (hybrid graphics)";
    };
    intel = {
      name = "intel";
      package = nixgl.packages.${pkgs.system}.nixGLIntel;
      binary = "nixGLIntel";
      description = "Intel integrated graphics";
    };
  };

  # Selected variant
  selectedVariant = nixGLVariants.${cfg.nixGLVariant};

in
{
  options.systemConfig = {
    systemType = lib.mkOption {
      type = lib.types.enum [ "desktop" "laptop" "minimal" "server" ];
      default = "desktop";
      description = ''
        The type of system being configured.
        - desktop: Full desktop setup with GPU acceleration
        - laptop: Portable setup with power saving options
        - minimal: Basic setup without window manager
        - server: Headless configuration
      '';
    };

    nixGLVariant = lib.mkOption {
      type = lib.types.enum [ "none" "default" "nvidia" "bumblebee" "intel" ];
      default = "nvidia";
      description = ''
        Which nixGL variant to use for OpenGL applications.
        - none: No wrapper (use system OpenGL libraries)
        - default: Auto-detect the GPU type
        - nvidia: NVIDIA proprietary drivers (with version management)
        - bumblebee: NVIDIA Optimus hybrid graphics
        - intel: Intel integrated graphics
      '';
    };

    enableOnboarding = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable first-time onboarding mode. When true, shows configuration
        selection prompts on activation.
      '';
    };

    systemIdentifier = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "work-laptop";
      description = ''
        A unique identifier for this system. Used to load system-specific
        configurations from ~/.config/nix/systems/<identifier>.nix
      '';
    };

    # Computed values (read-only)
    nixGLPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "The selected nixGL package (computed)";
    };

    nixGLBinary = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "The nixGL binary name or null if none selected";
    };

    nixGLWrapper = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "Full path to nixGL wrapper or null";
    };

    hasGPUAcceleration = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether GPU acceleration is configured";
    };
  };

  config = {
    # Set computed values
    systemConfig.nixGLPackage = selectedVariant.package;
    systemConfig.nixGLBinary = selectedVariant.binary;
    systemConfig.nixGLWrapper =
      if selectedVariant.binary != null
      then "${selectedVariant.package}/bin/${selectedVariant.binary}"
      else null;
    systemConfig.hasGPUAcceleration = cfg.nixGLVariant != "none";
  };
}
