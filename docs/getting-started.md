# Getting Started

Complete setup guide from clone to running system.

## Prerequisites

- Ubuntu 22.04+ (or compatible)
- Nix package manager with flakes
- git

## 1. Clone the Repository

```bash
# Clone the fork to ~/.config/nix
git clone -b dynamic-nvidia-version https://github.com/Tramscan/ubuntu-nix-config.git ~/.config/nix

# Enter directory
cd ~/.config/nix
```

## 2. Run Onboarding

```bash
# Start the interactive wizard
./scripts/onboard.sh
```

**Follow the prompts:**

1. **System name** - e.g., `laptop-x1` or `desktop-rtx4090`
2. **System type** - `laptop`, `desktop`, `minimal`, or `headless`
3. **Graphics** - Select nixGL variant (auto-detected)
4. **NVIDIA options** - Enable auto-detect or pin version

## 3. Apply Configuration

```bash
# Switch to the new configuration
home-manager switch --flake ~/.config/nix

# OR use the alias (after first switch)
hm-switch
```

## 4. Enable Documentation Server (Optional)

Add to your system configuration (`~/.config/nix/systems/<name>.nix`):

```nix
{
  systemConfig.enableDocsServer = true;
  systemConfig.docsServerPort = 8080;
}
```

Then apply:

```bash
home-manager switch --flake ~/.config/nix
systemctl --user enable just-enough-nix-docs
systemctl --user start just-enough-nix-docs
```

Access at `http://localhost:8080`

## 5. Managing NVIDIA Versions

**Check status:**
```bash
./scripts/nvidia-version-manager.sh status
```

**Pin specific version:**
```bash
./scripts/nvidia-version-manager.sh set-override 570.133.07
home-manager switch --flake ~/.config/nix
```

**Enable auto-detection:**
```bash
./scripts/nvidia-version-manager.sh clear-override
```

## Troubleshooting

**Hyprland won't start after NVIDIA update:**
```bash
# Switch to TTY (Ctrl+Alt+F3)
./scripts/nvidia-version-manager.sh update
home-manager switch --flake ~/.config/nix
```

**Unfree packages blocked:**
```bash
# Should be automatic, but if needed:
export NIXPKGS_ALLOW_UNFREE=1
```

**Impure flakes:**
```bash
# If you get impure errors (shouldn't happen after onboarding):
home-manager switch --flake ~/.config/nix --impure
```

## Next Steps

- [Repository Overview](R.0-Overview.md) - Understanding the structure
- [NVIDIA Version Management](R.0.1-NVIDIA-Version-Management.md) - Detailed feature docs
- [🎯 Interactive Demo](demo.html) - Try the onboarding wizard
