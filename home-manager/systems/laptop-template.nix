# laptop-template.nix
# Example system-specific configuration for a laptop
# Copy this to ~/.config/nix/systems/my-laptop.nix and customize

{ config, lib, ... }:

{
  # System identification
  systemConfig = {
    systemType = "laptop";          # desktop, laptop, minimal, server
    nixGLVariant = "intel";           # none, default, nvidia, bumblebee, intel
    systemIdentifier = "my-laptop";
  };

  # NVIDIA settings (only relevant if nixGLVariant = "nvidia")
  nvidiaManagement = {
    enableAutoDetection = true;       # Auto-detect on boot (true/false)
    manualVersion = null;             # Pin to version like "570.133.07" or null
    regenerateDesktopFile = false;      # Don't need .desktop on laptop (use TTY/login)
  };

  # NOTE: All sessionVariables should go in home.nix, not here.
  # This prevents infinite recursion from duplicate definitions.
  # If needed, use: home.sessionVariables = lib.mkDefault { ... };

  # Laptop-specific settings
  # home.sessionVariables = {
  #   # Power saving for laptop
  #   __GL_SYNC_DISPLAY_DEVICE = "DP-0";  # If using external monitor
  # };
}
