{ config, pkgs, lib, inputs, nixgl, ... }:

let
  # Create custom nixGL wrapper with explicit NVIDIA version
  nixGLWithVersion = let
    nvidiaVersion = "535.154.05"; # REPLACE WITH YOUR VERSION
    nixGLBase = nixgl.packages.${pkgs.system}.nixGLNvidia;
  in pkgs.runCommand "nixGLNvidia-custom" {} ''
    mkdir -p $out/bin
    cat > $out/bin/nixGLNvidia <<EOF
    #!${pkgs.bash}/bin/bash
    export NVIDIA_DRIVER_VERSION=${nvidiaVersion}
    exec ${nixGLBase}/bin/nixGLNvidia "\$@"
    EOF
    chmod +x $out/bin/nixGLNvidia
  '';

  nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
    mkdir -p $out/bin
    for bin in ${pkg}/bin/*; do
      wrapped_bin=$out/bin/$(basename $bin)
      echo "#!${pkgs.bash}/bin/bash" > $wrapped_bin
      echo "exec ${nixGLWithVersion}/bin/nixGLNvidia $bin \"\$@\"" >> $wrapped_bin
      chmod +x $wrapped_bin
    done
  '';
  
  wrappedAlacritty = nixGLWrap pkgs.alacritty;
  
  hyprlandModule = import ./apps/hyprland/default.nix {
    inherit pkgs inputs config lib;
    nixGLWithVersion = nixGLWithVersion; # Pass custom wrapper
  };
in {
rec {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "nick";
  home.homeDirectory = "/home/nick";
  

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.

  home.stateVersion = "24.05"; # Please read the comment before changing.
#  system = { 
#  	autoUpgrade = {
#		enable = true;
#		dates = "daily";
#		allowReboot = false;
#		};
#	};
  
  nixpkgs.config = {
    allowUnfree = true;
  };

  nixpkgs.overlays = [
    (final: prev: {
      mesa = pkgsMesa24_2_7.mesa;
    })
  ];

  imports = [
  	./apps/i3
	./apps/nixvim
	./apps/alacritty
	#(builtins.fetchurl {
	#  url = "https://raw.githubusercontent.com/Smona/home-manager/nixgl-compat/modules/misc/nixgl.nix";
	#  sha256 = "f14874544414b9f6b068cfb8c19d2054825b8531f827ec292c2b0ecc5376b305";
        #})
	./apps/hyprland
  ];


  nixpkgs.config.allowUnfreePredicate = (pkg: true);
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
  	neofetch
	vesktop
	picom
	# i3blocks
	waybar
	protonup-qt
	mujoco
	freecad
	mesa
	#nixGLPackage
	wrappedAlacritty
	gh
	pavucontrol
	zenith-nvidia
	obsidian
	libva
	egl-wayland
	wayland
	wayland-protocols
	libglvnd
	xwayland
	#hyprlandModule.hyprlandWrapper
	# hyprland
    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Helloauto.nixGLDefault: Tries to auto-detect and install Nvidia, if not, fallback to mesa. Recommended. Invoke with nixGL program., ${config.home.username}!"
    # '')
  ];
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nick/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
    SYSTEMD_EDITOR = "nvim";
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "alacritty";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";

    #Hyprland NVIDIA Variables
    #WLR_RENDERER = "vulkan";
    #GBM_BACKEND = "nvidia-drm";
    #__GLX_VENDOR_LIBRARY_NAME = "nvidia";
    #LIBVA_DRIVER_NAME = "nvidia"; # For hardware video acceleration
    #QT_QPA_PLATFORM = "wayland";
    #GDK_BACKEND = "wayland";
    #XDG_CURRENT_DESKTOP = "Hyprland";
    #XDG_SESSION_TYPE = "wayland";
    #XDG_SESSION_DESKTOP = "Hyprland";
    #AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:01:00.0-card:/dev/dri/by-path/pci-0000:11:00.0-card";
    #WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:01:00.0-card:/dev/dri/by-path/pci-0000:11:00.0-card";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" "auto-allocate-uids"];
      auto-optimise-store = true;
      auto-allocate-uids = true;
      max-jobs = "auto";
      trusted-users = [ "nick" ];
      extra-experimental-features = ["auto-allocate-uids"];
    };
    package = pkgs.nix;
  };

  # Remove the nixpkgs.overlays section if it exists

  # Your remaining configurations...

  # Configure Alacritty
  programs.alacritty = {
    enable = true;
    package = wrappedAlacritty;
  };

}
