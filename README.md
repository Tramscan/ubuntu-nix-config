# ubuntu-nix-configs
These configs require some setup to get started. This is a Nix config of Hyprland (or i3 if you want) using home-manager, designed to be used with Ubuntu and Nvidia GPU systems. 
## Setup
1. Install git and nix

'''
TODO
'''

2. Clone the repo

'''
git clone TODO UBUNTU_NIX_CONFIG_LOCATION
'''

3. Install graphics drivers/dependencies
Listed below are the reccomended drivers for Nvidia GPUs as this is what I've gotten working most recently. In the future I will update this to either autodetect the nvidia driver version for the nixGL portion of 'home.nix' and the 'hyprland.desktop' wrapping, but that is a future nick task.

'''
sudo apt update
sudo apt install nvidia-driver-570=570.133.07-0ubuntu0.22.04.1 libnvidia-gl-570=570.133.07-0ubuntu0.22.04.1 libnvidia-egl-gbm1=1.1.0-1 libnvidia-egl-wayland1=1.1.10-1 libegl1 libgl1 libglvnd0 libglx0 libdrm2 libgbm1 libxcb-randr0 libexpat1
'''

4. Switch the configuration

'''
home-manager switch --flake UBUNTU_NIX_CONFIG_LOCATION
'''

5. Modify your '/usr/share/wayland-sessions/hyprland.desktop'
'sudo nano /usr/share/wayland-sessions/hyprland.desktop'
The 'Exec=' block should look like this:

'''
Exec=env WLR_RENDERER=vulkan GBM_BACKEND=nvidia-drm __GLX_VENDOR_LIBRARY_NAME=nvidia LIBVA_DRIVER_NAME=nvidia XDG_SESSION_TYPE=wayland LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm NIXPKGS_ALLOW_UNFREE=1 nixGLNvidia-570.133.07 Hyprland
'''

Or, if you want the whole file:
'sudo nano /usr/share/wayland-sessions/hyprland.desktop'

'''
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=env WLR_RENDERER=vulkan GBM_BACKEND=nvidia-drm __GLX_VENDOR_LIBRARY_NAME=nvidia LIBVA_DRIVER_NAME=nvidia XDG_SESSION_TYPE=wayland LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm NIXPKGS_ALLOW_UNFREE=1 nixGLNvidia-570.133.07 Hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
'''

6. Create a systemd service for gbm libraries such as 'setup-opengl-symlinks.service'
'sudo nano /etc/systemd/system/setup-opengl-symlinks.service'

'''
# /etc/systemd/system/setup-opengl-symlinks.service
[Unit]
Description=Setup OpenGL symlinks before display manager
DefaultDependencies=no
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/home/nick/.config/nix/home-manager/scripts/setup-opengl-symlinks.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
'''

7. Enable and start the service

'''
sudo systemctl daemon-reload
sudo systemctl enable setup-opengl-symlinks.service
sudo systemctl start setup-opengl-symlinks.service
'''

8. Reboot and log in to Hyprland

#Conclusion

Although these are more steps than you'd want for something as simple as Hyprland on Nix (which ___should___ be a few lines at most), Nvidia is tricky to set up for wayland on non-nixos systems. If you have NixOS, there is not much of a reason to use this configuration. However, I know that there are a lot of packages that are great to use natively on Ubuntu and rely on the system-level graphics libraries, so this is a great middle-ground where you can have your cake (riced and declarative Hyprland configured through nix) and eat it too (use Ubuntu LTS and packages unavailable to the nix package manager). Let me know if these are redundant to some NixOS magic and I'll gladly archive this repo and switch ASAP.

visit my website at [nickcline.com](https://nickcline.com) and please hire me
