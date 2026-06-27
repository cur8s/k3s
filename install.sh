#!/usr/bin/env bash
# Install single-node k3s on an Ubuntu
# Each setting is its own k3s env var below — edit and run:  ./install.sh
# Uninstall:  sudo /usr/local/bin/k3s-uninstall.sh
set -euo pipefail

export INSTALL_K3S_CHANNEL="stable"          # install the current stable release
export INSTALL_K3S_EXEC="--disable=traefik"  # disable bundled Traefik (k3s has no env var for --disable)

curl -sfL https://get.k3s.io | sh -

echo "k3s installed — check it with: sudo k3s kubectl get nodes"
