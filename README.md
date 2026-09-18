# archlinux-repo

Pacman repository for running Arch Linux on the Microsoft Surface Pro 11
(Denali), built on top of [Arch Linux Ports](https://ports.archlinux.page).

Packages are built by CI and published as release assets.

## Install the keyring

```sh
curl -LO https://raw.githubusercontent.com/dwhinham/archlinux-repo/main/dwhinham-keyring/dwhinham.gpg
sudo pacman-key --add dwhinham.gpg
sudo pacman-key --lsign-key 1565514CFA0B8E619ABB379861CC72A6A05CD688
```

## Add the repository

Add to `/etc/pacman.conf`, above `[core]`:

```ini
[dwhinham]
Server = https://github.com/dwhinham/archlinux-repo/releases/download/$arch
```

Then sync, and install the keyring package so future key changes arrive as
updates:

```sh
sudo pacman -Syu dwhinham-keyring
```

Surface Pro 11 packages are collected in a group:

```sh
sudo pacman -S sp11
```

## Credits

The build setup here follows
[ironrobin/aarch64](https://codeberg.org/ironrobin/aarch64), which also serves
packages as forge release assets.
