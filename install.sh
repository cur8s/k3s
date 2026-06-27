#!/usr/bin/env bash
# Install single-node k3s on an Ubuntu VM.
# Each setting is its own k3s env var below — edit and run:  ./install.sh
# Uninstall:  sudo /usr/local/bin/k3s-uninstall.sh
set -euo pipefail

export INSTALL_K3S_VERSION="v1.36.2+k3s1"    # k3s release to install
export K3S_KUBECONFIG_MODE="644"             # world-readable kubeconfig (kubectl without sudo)
export INSTALL_K3S_EXEC="--disable=traefik"  # disable bundled Traefik (k3s has no env var for --disable)

curl -sfL https://get.k3s.io | sh -

# Point kubectl at the new cluster for the current user.
mkdir -p "$HOME/.kube"
cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

echo "k3s ready — try: kubectl get nodes"
