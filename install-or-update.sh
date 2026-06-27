#!/usr/bin/env bash
# Install single-node k3s on Ubuntu.
#
# Each install path and runtime setting is recorded here so the generated
# systemd service is easy to reason about later. Edit these values before
# running ./install-or-update.sh if you want a different layout.
#
# Uninstall: sudo /usr/local/bin/k3s-uninstall.sh
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  cat >&2 <<EOF
ERROR: install-or-update.sh must be run as root.

k3s installs binaries, systemd units, kubeconfig, and cluster state into
root-owned locations. Run:

  sudo ./install-or-update.sh
EOF
  exit 1
fi

# Installer-managed paths.
export INSTALL_K3S_BIN_DIR="/usr/local/bin"          # k3s binary, kubectl/crictl/ctr symlinks, uninstall script

# Runtime paths used by k3s itself.
export K3S_DATA_DIR="/var/lib/rancher/k3s"           # cluster state, containerd data, kubelet data, embedded DB
export K3S_KUBECONFIG_OUTPUT="/etc/rancher/k3s/k3s.yaml"
export K3S_KUBECONFIG_MODE="0600"                   # require sudo/root to read the admin kubeconfig

# Release and server flags.
export INSTALL_K3S_CHANNEL="v1.35"                   # track latest k3s patch for Kubernetes v1.35
export INSTALL_K3S_EXEC="server --disable=traefik"   # single-node server; disable bundled Traefik

cat <<EOF
Installing k3s with these paths:
  binary/tools:      ${INSTALL_K3S_BIN_DIR}
  systemd unit/env:  /etc/systemd/system/k3s.service(.env)
  config directory:  /etc/rancher/k3s
  kubeconfig:        ${K3S_KUBECONFIG_OUTPUT}
  data directory:    ${K3S_DATA_DIR}
  sqlite datastore:  ${K3S_DATA_DIR}/server/db/state.db
  uninstall script:  ${INSTALL_K3S_BIN_DIR}/k3s-uninstall.sh
EOF

curl -sfL https://get.k3s.io | sh -

echo "k3s installed. Check it with: sudo k3s kubectl get nodes"
