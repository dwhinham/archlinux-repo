#!/bin/bash
# Build the packages in packages.list into out/ and make a pacman repo of them.
# Runs in an Arch Linux Ports aarch64 container with the repo at /build.
# Packages already in out/ are not rebuilt; bump pkgrel to force one.

set -euo pipefail

# Keep makepkg's scratch space out of the workspace: chowning the checkout
# would break the runner's post-job git cleanup.
export PKGDEST=/build/out BUILDDIR=/tmp/makepkg SRCDEST=/tmp/makepkg-src

pacman-key --init
pacman -Syu --noconfirm --needed base-devel

# makepkg refuses to run as root.
useradd -m builduser
printf 'builduser ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builduser
mkdir -p "$PKGDEST" "$BUILDDIR" "$SRCDEST"
chown builduser:builduser "$PKGDEST" "$BUILDDIR" "$SRCDEST"

base64 -d <<< "$SIGNING_KEY" | sudo -u builduser gpg --batch --import

while read -r dir; do
	[[ -n "$dir" && "$dir" != \#* ]] || continue
	cd "/build/$dir"
	# makepkg exits 13 when the package is already built.
	sudo -u builduser --preserve-env=PKGDEST,BUILDDIR,SRCDEST \
		makepkg -s --noconfirm --sign < /dev/null || [[ $? == 13 ]]
done < /build/packages.list

cd "$PKGDEST"
sudo -u builduser repo-add --sign dwhinham.db.tar.gz ./*.pkg.tar.zst

# Release assets cannot be symlinks.
for link in *.db *.files; do
	cp --remove-destination "$(readlink -f "$link")" "$link"
done
