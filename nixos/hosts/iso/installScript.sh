 #!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="/etc/nixos/homelab"
CONFIG_DIR="$TARGET_DIR/nixos"

# Clone repo
if [ ! -d "$TARGET_DIR/.git" ]; then
    mkdir $TARGET_DIR
    cd $TARGET_DIR

    git init
    git remote add -f origin https://github.com/KGB33/homelab.git
    git config core.sparseCheckout true
    echo "nixos" >> .git/info/sparse-checkout
    git pull origin main
fi

TARGET_HOST=$(ls -1 $CONFIG_DIR/hosts/*/configuration.nix | cut -d'/' -f7 | rg -v 'iso|base' | gum choose)

if [ ! -e "$CONFIG_DIR/hosts/$TARGET_HOST/disks.nix" ]; then
	echo "ERROR! $(basename "$0") could not find the required $CONFIG_DIR/hosts/$TARGET_HOST/disks.nix"
	exit 1
fi

gum confirm  --default=false \
    "🔥 🔥 🔥 WARNING!!!! This will ERASE ALL DATA on the disk $TARGET_HOST. Are you sure you want to continue?"

echo "Partitioning Disks"
sudo nix run github:nix-community/disko \
    --extra-experimental-features "nix-command flakes" \
    --no-write-lock-file \
    -- \
    --mode zap_create_mount \
    "$HOME/dotfiles/hosts/$TARGET_HOST/disks.nix"

sudo nixos-install --flake "$HOME/dotfiles#$TARGET_HOST"
