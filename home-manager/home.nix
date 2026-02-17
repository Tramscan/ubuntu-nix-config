{ config, pkgs, lib, inputs, nixgl, ... }:

let
  # System config loading
  # Check for active-system config file
  activeSystemFile = "${config.home.homeDirectory}/.config/nix/active-system";
  systemConfigFile = "/home/nick/.config/nix/systems/laptop.nix"; # Change this per system
  
  # Check if we should use system-specific config
  hasSystemConfig = builtins.pathExists systemConfigFile;
  
  # NVIDIA version - if no config, use defaults
  nvidiaVersion = 
    if config.nvidiaManagement.manualVersion != null 
    then config.nvidiaManagement.manualVersion
    else config.nvidiaManagement.fallbackVersion;

  # Build nixGL command
  nixGLCmd = let
    variant = config.systemConfig.nixGLVariant;
    base = nixgl.packages.${pkgs.system};
  in
    if variant == "none" then null
    else if variant == "nvidia" then "${base.nixGLNvidia}/bin/nixGLNvidia-${nvidiaVersion}"
    else if variant == "default" then "${base.nixGLDefault}/bin/nixGLDefault"
    else if variant == "bumblebee" then "${base.nixGLNvidiaBumblebee}/bin/nixGLNvidiaBumblebee"
    else if variant == "intel" then "${base.nixGLIntel}/bin/nixGLIntel"
    else null;

  wrappedSteam = pkgs.writeShellScriptBin "steam" ''
    LD_LIBRARY_PATH= exec /usr/bin/steam "$@"
  '';

in
{
  imports = [
    ./nvidia-config.nix
    ./system-config.nix
    ./apps/i3
    ./apps/nixvim
    ./apps/alacritty
    ./apps/hyprland
    ./apps/waybar
    ./apps/firefox
    ./apps/vesktop
    ./apps/kicad
    # Optional: Import system-specific config if it exists
  ] ++ lib.optional hasSystemConfig systemConfigFile;

  # Allow unfree without env var
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);

  # Basic settings
  home.username = "nick";
  home.homeDirectory = "/home/nick";
  home.stateVersion = "24.05";

  # Defaults (overridden by imported system config)
  systemConfig = {
    systemType = lib.mkDefault "desktop";
    nixGLVariant = lib.mkDefault "nvidia";
  };

  nvidiaManagement = {
    enableAutoDetection = lib.mkDefault true;
    manualVersion = lib.mkDefault null;
    regenerateDesktopFile = lib.mkDefault true;
    fallbackVersion = "570.133.07";
  };

  # NVIDIA service
  systemd.user.services.nvidia-version-manager = lib.mkIf (config.systemConfig.nixGLVariant == "nvidia") {
    Unit = {
      Description = "NVIDIA Driver Version Manager";
      Before = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = let
        script = pkgs.writeShellScript "nvidia-version-service" ''
          CONFIG="$HOME/.config/nix"
          mkdir -p "$CONFIG"
          
          DETECTED=""
          if command -v nvidia-smi &>/dev/null; then
            DETECTED=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]' || true)
          fi
          [ -z "$DETECTED" ] && DETECTED="${nvidiaVersion}"
          
          echo "[nvidia-version] Version: $DETECTED"
          echo "NVIDIA_VERSION=$DETECTED" > "$CONFIG/nvidia-version.conf"
        '';
      in "${script}";
      RemainAfterExit = true;
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
  };

  # Packages
  home.packages = with pkgs; [
    neofetch picom waybar protonup-qt mujoco freecad mesa-demos
    alacritty gh pavucontrol zenith-nvidia obsidian
    libva egl-wayland wayland wayland-protocols libglvnd xwayland
    nixgl.packages.${pkgs.system}.nixGLNvidia
    nixgl.packages.${pkgs.system}.nixGLDefault
    nixgl.packages.${pkgs.system}.nixGLNvidiaBumblebee
    nixgl.packages.${pkgs.system}.nixGLIntel
    wofi wrappedSteam qbittorrent sunshine pipewire nodejs_24
  ];

  # Session variables (but not NIXPKGS_ALLOW_UNFREE - that's in nix.conf)
  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
    SYSTEMD_EDITOR = "nvim";
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "alacritty";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    NIXOS_OZONE_WL = "1";
  };

  # Shell aliases (for convenience)
  programs.bash.shellAliases = {
    "hm-switch" = "home-manager switch --flake ~/.config/nix";
    "nvidia-update" = "~/.config/nix/scripts/nvidia-version-manager.sh update";
  };
  programs.zsh.shellAliases = {
    "hm-switch" = "home-manager switch --flake ~/.config/nix";
    "nvidia-update" = "~/.config/nix/scripts/nvidia-version-manager.sh update";
  };

  # nix.conf - this makes ALLOW_UNFREE automatic
  home.file.".config/nix/nix.conf".text = ''
    experimental-features = nix-command flakes auto-allocate-uids
    auto-optimise-store = true
    allow-unfree = true
    accept-flake-config = true
  '';

  programs.home-manager.enable = true;
  programs.kitty.enable = true;
  programs.alacritty = { enable = true; };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" "auto-allocate-uids"];
      auto-optimise-store = true;
      max-jobs = "auto";
      trusted-users = [ "nick" ];
    };
    package = pkgs.nix;
  };
}
