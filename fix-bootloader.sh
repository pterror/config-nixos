#!/usr/bin/env bash
set -euo pipefail

sudo nix run nixpkgs#efibootmgr -- -B -b 0005
sudo nix run nixpkgs#efibootmgr -- -o 0003,0000,0001,0002
sudo rm -rf /boot/EFI/systemd /boot/loader
sudo nixos-rebuild boot --flake .
sudo nix run nixpkgs#efibootmgr -- -v
