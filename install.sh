#!/usr/bin/env bash
# Install single-node k3s on an Ubuntu VM.
#
#   - pinned to v1.36.2+k3s1
#   - Traefik disabled            (bring your own ingress)
#   - world-readable kubeconfig   (kubectl works without sudo)
#
# Edit the env vars below to change the install. Then:  ./install.sh
# Uninstall:  sudo /usr/local/bin/k3s-uninstall.sh
set -euo pipefail

# --- k3s install settings ---------------------------------------------------
export INSTALL_K3S_VERSION="v1.36.2+k3s1"
export INSTALL_K3S_EXEC="server --disable=traefik --write-kubeconfig-mode=0644"

# --- install ----------------------------------------------------------------
# The official installer reads the env vars above and elevates with sudo itself.
curl -sfL https://get.k3s.io | sh -

# Point kubectl at the new cluster for the current user.
mkdir -p "$HOME/.kube"
cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

echo "k3s ready — try: kubectl get nodes"
