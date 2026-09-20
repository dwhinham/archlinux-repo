#!/bin/bash
# Build the packages in packages.list into out/ and make a pacman repo of them.
# Runs in an Arch Linux Ports aarch64 container with the repo at /build.
# Packages already in out/ are not rebuilt; bump pkgrel to force one.

set -euo pipefail

export PKGDEST=/build/out BUILDDIR=/tmp/makepkg SRCDEST=/tmp/makepkg-src
export MAKEFLAGS="-j$(nproc)"
export CCACHE_DIR=/build/.ccache CCACHE_MAXSIZE=4G

pacman-key --init
pacman -Syu --noconfirm --needed base-devel ccache
sed -i 's/!ccache/ccache/' /etc/makepkg.conf

# makepkg refuses to run as root.
useradd -m builduser
printf 'builduser ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builduser
mkdir -p "$PKGDEST" "$BUILDDIR" "$SRCDEST" "$CCACHE_DIR"
chown builduser:builduser "$PKGDEST" "$BUILDDIR" "$SRCDEST"
# Recursive: the cache is restored as the runner's uid, so the directories
# inside it would otherwise stay unwritable by builduser.
chown -R builduser:builduser "$CCACHE_DIR"

base64 -d <<< "$SIGNING_KEY" | sudo -u builduser gpg --batch --import

while read -r dir; do
	[[ -n "$dir" && "$dir" != \#* ]] || continue
	cd "/build/$dir"

	# makepkg exits 13 when the package is already built.
	sudo -u builduser --preserve-env=PKGDEST,BUILDDIR,SRCDEST,MAKEFLAGS,CCACHE_DIR,CCACHE_MAXSIZE \
		makepkg -s --noconfirm --sign < /dev/null || [[ $? == 13 ]]
done < /build/packages.list

sudo -u builduser --preserve-env=CCACHE_DIR ccache --show-stats || true
# The runner archiving the cache is a different uid than the container's builduser.
chmod -R a+rX "$CCACHE_DIR"

cd "$PKGDEST"
sudo -u builduser repo-add --sign dwhinham.db.tar.gz ./*.pkg.tar.zst

# Release assets cannot be symlinks.
for link in *.db *.files; do
	cp --remove-destination "$(readlink -f "$link")" "$link"
done
