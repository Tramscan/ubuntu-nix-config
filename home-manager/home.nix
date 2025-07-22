{ config, pkgs, lib, inputs, nixgl, ... }:

let
  # Create custom nixGL wrapper with explicit NVIDIA version
  #nixGLWithVersion = let
  #  nvidiaVersion = "535.230.02"; # REPLACE WITH YOUR VERSION
  #  nixGLBase = nixgl.packages.${pkgs.system}.nixGLNvidia;
  #in pkgs.runCommand "nixGLNvidia-custom" {} ''
  #  mkdir -p $out/bin
  #  cat > $out/bin/nixGLNvidia <<EOF
    #!${pkgs.bash}/bin/bash
  #  export NVIDIA_DRIVER_VERSION=${nvidiaVersion}
  #  exec ${nixGLBase}/bin/nixGLNvidia "\$@"
  #  EOF
  #  chmod +x $out/bin/nixGLNvidia
  #'';

  #nixGLNvidiaBin = "${nixgl.packages.${pkgs.system}.nixGLNvidia}/bin/nixGLNvidia";
  #alacrittyBin = "${pkgs.alacritty}/bin/alacritty";
  #nvidiaVersion = "535.230.02";

  #wrapWithNixGL = 0; # Toggle this between 1 and 0
  #alacrittyBin = "${pkgs.alacritty}/bin/alacritty";
  #vesktopBin = "${pkgs.vesktop}/bin/vesktop";
  #nixGLNvidiaBin = "${nixgl.packages.${pkgs.system}.nixGLNvidia}/bin/nixGLNvidia";
  #wrappedAlacritty = pkgs.writeShellScriptBin "alacritty" ''
  #  exec ${nixGLNvidiaBin} ${alacrittyBin} "$@"
  #'';

  #wrappedVesktop = pkgs.writeShellScriptBin "vesktop" ''
  #  exec ${nixGLNvidiaBin} ${vesktopBin} "$@"
  #'';
  #wrappedAlacritty = pkgs.writeShellScriptBin "alacritty-nixgl" ''
  #  export NVIDIA_DRIVER_VERSION=${nvidiaVersion}
  #  exec ${nixGLNvidiaBin} ${alacrittyBin} "$@"
  #'';
  wrappedSteam = pkgs.writeShellScriptBin "steam" ''
    LD_LIBRARY_PATH= exec /usr/bin/steam "$@"
  '';
 # pkgsMesa24_2_7 = import inputs.nixpkgs-mesa-24-2-7 {
 #   inherit (pkgs) system;
 # };

 # sunshineAudioScript = pkgs.writeShellScriptBin "sunshine-audio-setup" ''
    #!${pkgs.runtimeShell}
    # Load the virtual sink
 #   ${pkgs.pulseaudio}/bin/pactl load-module module-null-sink sink_name=sunshine-sink sink_properties=device.description="Sunshine_Virtual_Sink"
    
    # Load the virtual microphone that listens to the sink
#    ${pkgs.pulseaudio}/bin/pactl load-module module-remap-source master=sunshine-sink.monitor source_name=sunshine-mic source_properties=device.description="Sunshine_Mic"
#  '';

  nixGLNvidia = "${nixgl.packages.${pkgs.system}.nixGLNvidia}/bin/nixGLNvidia-570.133.07";
  

 # hyprlandModule = import ./apps/hyprland/default.nix {
 #   inherit pkgs inputs config lib;
 #   nixGLWithVersion = nixGLWithVersion; # Pass custom wrapper
 # };
in rec{
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

  #nixpkgs.overlays = [
  #  (final: prev: {
  #    mesa = pkgsMesa24_2_7.mesa;
  #  })
  #];

  imports = [
  	./apps/i3
	./apps/nixvim
	./apps/alacritty
	#(builtins.fetchurl {
	#  url = "https://raw.githubusercontent.com/Smona/home-manager/nixgl-compat/modules/misc/nixgl.nix";
	#  sha256 = "f14874544414b9f6b068cfb8c19d2054825b8531f827ec292c2b0ecc5376b305";
        #})
	./apps/hyprland
	./apps/waybar
	./apps/firefox
	#maybe consider making a few more for ryujinx and steam so you can fix the desktop entries
	./apps/vesktop
  ];


  nixpkgs.config.allowUnfreePredicate = (pkg: true);
  # The home.packages option allows you to install Nix packages into your
  # environment.

  # 1. Create a startup script for our audio setup
  # This avoids editing system files and runs commands we know are safe.
#  systemd.user.services."sunshine-audio-setup" = {
#    Unit = {
#      Description = "Setup virtual audio devices for Sunshine";
#      # This is critical: it waits until your main audio service is running.
#      After = [ "pulseaudio.service" ];
#    };

 #   Service = {
 #     # We use a simple shell script to run the commands.
 #     Type = "oneshot";
 #     ExecStart = "${sunshineAudioScript}/bin/sunshine-audio-setup";
 #   };

 #   Install = {
      # This ensures the script runs when you log in.
 #     WantedBy = [ "default.target" ];
 #   };
 # };

  # 2. Fix the video capture error by enabling the correct portal for Hyprland
  # This part is still necessary for Wayland screen sharing.
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # 3. Manage Sunshine with Nix to ensure it runs correctly as a user service
  systemd.user.services.sunshine = {
    Unit = {
      Description = "Sunshine Game Stream Host";
      # This ensures the audio devices are created BEFORE Sunshine starts.
      #After = [ "graphical-session.target" "sunshine-audio-setup.service" ];
      After = [ "graphical-session.target" ];
      #Wants = [ "sunshine-audio-setup.service" ];
    };
    Service = {
      # We get the sunshine command from the package we install below.
      ExecStart = "${nixgl.packages.${pkgs.system}.nixGLNvidia}/bin/nixGLNvidia-570.133.07 ${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };


  home.packages = with pkgs; [
  	neofetch
	#( if wrapWithNixGL == 1 then wrappedVesktop else vesktop )
	picom
	#i3blocks
	waybar
	protonup-qt
	mujoco
	freecad
	mesa-demos
	#nixGLPackage
	#( if wrapWithNixGL == 1 then wrappedAlacritty else alacritty )
	alacritty
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
	nixgl.packages.${pkgs.system}.nixGLNvidia
	nixgl.packages.${pkgs.system}.nixGLDefault
	nixgl.packages.${pkgs.system}.nixGLNvidiaBumblebee
	wofi
	wrappedSteam
	qbittorrent
	sunshine
	#pokemmo-installer
	  (pkgs.pokemmo-installer.overrideAttrs (oldAttrs: {
	      buildInputs = (oldAttrs.buildInputs or []) ++ [ pkgs.makeWrapper ]; # Include makeWrapper in buildInputs
	      postInstall = ''
		wrapProgram "$out/bin/pokemmo-installer" \
		  --set __GL_THREADED_OPTIMIZATIONS 0 
	      '';
	    }))
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
    TERMINAL = "alacritty-nixglhost";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    NIXPKGS_ALLOW_UNFREE = 1;
    NIXOS_OZONE_WL = "1";

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
    };
    package = pkgs.nix;
  };

  # Remove the nixpkgs.overlays section if it exists
  
  # Your remaining configurations...
  programs.kitty.enable = true;
  # Configure Alacritty
  programs.alacritty = {
    enable = true;
    #package = wrappedAlacritty;
  };
  
  #systemd.user.sessionVariables = {
  #  NIXPKGS_ALLOW_UNFREE = "1";
  #  LIBGL_DRIVERS_PATH = "/run/opengl-driver/lib/gbm";
  #  LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  #  };

  #systemd services
  #systemd.user.services.setup-opengl-symlinks = {
  #  Unit = {
  #    Description = "Setup OpenGL symlinks before display manager";
  #    DefaultDependencies= "no";
  #    Before = "graphical-session.target";
  #  };
  #  Service = {
  #    Type = "oneshot";
  #    ExecStart = "/usr/bin/sudo /home/nick/.config/nix/home-manager/scripts/setup-opengl-symlinks.sh";
  #    RemainAfterExit = true;
  #  };
  #  Install = {
  #    WantedBy = [ "multi-user.target" ];
  #  };
  #};

}
