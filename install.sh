#!/usr/bin/env bash
# Install single-node k3s on an Ubuntu VM. Everything is hard-coded for
# simplicity:
#
#   - pinned to v1.36.2+k3s1
#   - Traefik disabled            (bring your own ingress)
#   - world-readable kubeconfig   (kubectl works without sudo)
#
# Usage:      ./install.sh            (you'll be prompted for your sudo password)
# Uninstall:  sudo /usr/local/bin/k3s-uninstall.sh
set -euo pipefail

# Install k3s. The official installer elevates with sudo on its own as needed.
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.36.2+k3s1" \
  INSTALL_K3S_EXEC="server --disable=traefik --write-kubeconfig-mode=0644" \
  sh -

# Point kubectl at the new cluster for the current user.
mkdir -p "$HOME/.kube"
cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

echo "k3s ready — try: kubectl get nodes"
