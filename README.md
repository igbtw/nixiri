## Features

* Niri
* systemd-boot
* NetworkManager
* systemd-resolved with Mullvad DNS
* Firewall + nftables
* Kernel hardening
* PipeWire
* Flatpak
* Steam
* LibreWolf
* ZRAM
* Automatic Nix garbage collection

## Installation

Start with a minimal NixOS installation.

Clone the repository:

```bash
sudo git clone https://github.com/igbtw/nixiri.git /etc/nixos
cd /etc/nixos
```

Generate the hardware configuration for your machine:

```bash
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

Review the configuration and change any machine-specific settings.

Then build the system:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

Reboot:

```bash
sudo reboot
```

## Updating

Update the flake inputs:

```bash
sudo nix flake update /etc/nixos
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

## Rollback

If something goes wrong, reboot and select a previous NixOS generation from the systemd-boot menu.

## Warning

This configuration is primarily designed for my own system. Review the configuration before applying it to your machine, especially hardware, users, filesystems, networking, and security settings.
