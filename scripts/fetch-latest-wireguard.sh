#!/bin/bash
set -e
USER_AGENT="WireGuard-AndroidROMBuild/0.1 ($(uname -a))"

[[ $(( $(date +%s) - $(stat -c %Y "net/wireguard/.check" 2>/dev/null || echo 0) )) -gt 86400 ]] || exit 0

[[ $(curl -A "$USER_AGENT" -LSs https://git.zx2c4.com/WireGuard/refs/) =~ snapshot/WireGuard-([0-9.]+)\.tar\.xz ]]

rm -rf net/wireguard
mkdir -p net/wireguard
curl -A "$USER_AGENT" -LsS "https://git.zx2c4.com/WireGuard/snapshot/WireGuard-${BASH_REMATCH[1]}.tar.xz" | tar -C "net/wireguard" -xJf - --strip-components=2 "WireGuard-${BASH_REMATCH[1]}/src"
touch net/wireguard/.check

#after https://github.com/fgl27/BHB27Kernel/commit/5c1cc037752bb9e4ca3e12ada879f79c35fc3e30
#we don't need that workaround
old="#if LINUX_VERSION_CODE < KERNEL_VERSION(3, 15, 0)"
new="#if LINUX_VERSION_CODE < KERNEL_VERSION(3, 10, 0)"
sed  --in-place "s%$old%$new%g" net/wireguard/compat/udp_tunnel/udp_tunnel.c
