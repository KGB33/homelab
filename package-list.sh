#!/bin/sh
[ -d vars ] || mkdir vars # Create dir if it does not exist

# Generate AUR package list
pacman -Qqm \
	| awk 'BEGIN{print "aur_packages:"}; {printf"  - %s\n", $1};' \
	> vars/aur_packages.yml

# Generate pacman package list
pacman -Qqe \
	| grep -v "$(pacman -Qqm)" \
	| awk 'BEGIN{print "pacman_packages:"}; {printf"  - %s\n", $1};' \
	> vars/pacman_packages.yml

# Generate pipx package list
pipx list \
	| grep "package" \
	| awk 'BEGIN{print "pipx_packages:"}; {printf"  - %s\n", $2};' \
	> vars/pipx_packages.yml
