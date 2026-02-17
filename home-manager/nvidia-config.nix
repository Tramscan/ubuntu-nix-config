# nvidia-config.nix
# Configuration for managing NVIDIA driver versions with nixGL
# This module provides options for:
# A. Automatic version detection (before display manager starts)
# B. Manual version override for downgrades

{ config, lib, pkgs, nixgl, ... }:

let
  cfg = config.nvidiaManagement;
in
{
  options.nvidiaManagement = {
    enableAutoDetection = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable automatic detection of NVIDIA driver version.
        When enabled, a systemd service will run before the display manager
        to detect the current NVIDIA driver version and regenerate configs.
        Set to false to disable automatic updates.
      '';
    };

    manualVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "570.133.07";
      description = ''
        Manual override for NVIDIA driver version.
        When set (e.g., "570.133.07"), this version will be used for nixGL
        instead of auto-detecting. This allows you to:
        - Pin a specific version
        - Downgrade after a problematic update
        - Test different driver versions

        Set to null (default) to use auto-detection (if enabled) or fall back
        to a default version.
      '';
    };

    regenerateDesktopFile = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to regenerate /usr/share/wayland-sessions/hyprland.desktop
        with the correct nixGL version. This requires root privileges.
        The script will use sudo if available.
      '';
    };

    desktopFilePath = lib.mkOption {
      type = lib.types.path;
      default = /usr/share/wayland-sessions/hyprland.desktop;
      description = ''
        Path where the Hyprland .desktop file should be written.
        Default is the system-wide location used by display managers.
      '';
    };

    fallbackVersion = lib.mkOption {
      type = lib.types.str;
      default = "570.133.07";
      description = ''
        Fallback NVIDIA driver version to use when auto-detection fails
        and no manual version is set.
      '';
    };
  };

  config = cfg;
}
