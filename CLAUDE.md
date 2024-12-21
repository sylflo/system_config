# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal system configuration repository containing:
- **NixOS configurations** using flakes for multiple hosts (desktop, personal-laptop, work-laptop)
- **Dotfiles** including Hyprland window manager configurations
- **Desktop UI application** - a Python GTK4 layer shell application for system controls

## Development Commands

### NixOS System Management
```bash
# Build and switch to a specific configuration
sudo nixos-rebuild switch --flake .#desktop
sudo nixos-rebuild switch --flake .#personal-laptop  
sudo nixos-rebuild switch --flake .#work-laptop

# Test configuration without switching
sudo nixos-rebuild test --flake .#desktop

# Build configuration only (no activation)
nixos-rebuild build --flake .#desktop

# Update flake inputs
nix flake update
```

### Desktop UI Development
```bash
# Enter development shell for the GTK4 application
cd dotfiles/desktop-ui
nix-shell

# Run the application (within nix-shell)
python main.py
```

### Home Manager
```bash
# Rebuild home manager configuration
home-manager switch --flake .#sylflo@desktop
```

## Architecture

### NixOS Configuration Structure
- **`flake.nix`** - Main flake entry point defining system configurations and inputs
- **`common/`** - Shared configuration modules
  - `configuration.nix` - System-wide NixOS configuration  
  - `home.nix` - Home Manager user configuration
- **`hosts/`** - Host-specific configurations
  - Each host has its own `configuration.nix`, `hardware-configuration.nix`, and optionally `home.nix`

The flake uses a `mkSystem` function to compose configurations from common modules and host-specific overrides.

### Key Components
- **Hyprland** - Wayland compositor configured via Home Manager with virtual desktops plugin
- **Home Manager** - Manages user environment, applications, and dotfiles  
- **GTK4 Layer Shell App** - Python application using PyGObject for system controls overlay

### Desktop UI Application
- **`main.py`** - Entry point with GTK4 layer shell setup and UI logic
- **`layouts/`** - UI definition files (.ui format)
- **`shell.nix`** - Development environment with GTK4, layer shell, and Python dependencies
- Features: brightness control, system settings, animated transitions

### Hyprland Configuration
- Main config sourced from `~/.config/hypr/hyprland-source.conf`
- Virtual desktops plugin configured with named workspaces: "1:coding", "2:internet", "3:mail and chats"
- Sticky window rules for specific applications

## Key Features
- Multi-host NixOS configurations with shared base
- Hyprland with virtual desktops and custom UI overlay
- Privacy-focused Firefox (LibreWolf) configuration
- Development tools: Python, Rust, VSCodium, Git
- System integration: Bluetooth, networking, brightness control