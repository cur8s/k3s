#!/usr/bin/env bash
# Install single-node k3s on an Ubuntu VM with pinned, opinionated defaults:
#
#   - pinned k3s version          (reproducible installs)
#   - Traefik disabled            (bring your own ingress)
#   - world-readable kubeconfig   (kubectl works without sudo)
#
# Run it as your normal user; it uses sudo only for the install step itself.
#
#   ./install.sh
#   K3S_VERSION=v1.35.1+k3s1 ./install.sh
#   K3S_TLS_SANS="203.0.113.10 k3s.example.com" ./install.sh
#
# Uninstall later with:  sudo /usr/local/bin/k3s-uninstall.sh
set -euo pipefail

# --- defaults (override any of these via the environment) --------------------
K3S_VERSION="${K3S_VERSION:-v1.36.2+k3s1}"
K3S_DISABLE_TRAEFIK="${K3S_DISABLE_TRAEFIK:-true}"
K3S_DISABLE_SERVICELB="${K3S_DISABLE_SERVICELB:-false}"
K3S_KUBECONFIG_MODE="${K3S_KUBECONFIG_MODE:-0644}"
K3S_TLS_SANS="${K3S_TLS_SANS:-}"
K3S_EXTRA_FLAGS="${K3S_EXTRA_FLAGS:-}"
K3S_INSTALL_URL="${K3S_INSTALL_URL:-https://get.k3s.io}"

log() { printf '\033[1;34m[k3s]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[k3s]\033[0m %s\n' "$*" >&2; exit 1; }

# --- preflight ---------------------------------------------------------------
command -v curl >/dev/null 2>&1 || die "curl is required but not installed"
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  command -v sudo >/dev/null 2>&1 || die "not running as root and sudo is not available"
  SUDO="sudo"
fi
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  [ "${ID:-}" = "ubuntu" ] || log "warning: OS '${ID:-unknown}' is not Ubuntu (untested, continuing)"
fi

# --- assemble the server flags -----------------------------------------------
flags="--write-kubeconfig-mode=${K3S_KUBECONFIG_MODE}"
[ "${K3S_DISABLE_TRAEFIK}" = "true" ]   && flags="--disable=traefik ${flags}"
[ "${K3S_DISABLE_SERVICELB}" = "true" ] && flags="--disable=servicelb ${flags}"
for san in ${K3S_TLS_SANS}; do flags="${flags} --tls-san=${san}"; done
[ -n "${K3S_EXTRA_FLAGS}" ] && flags="${flags} ${K3S_EXTRA_FLAGS}"

# --- install -----------------------------------------------------------------
# Pass config explicitly through `env` so it survives sudo regardless of the
# sudoers policy. The inner `curl | sh` is the official k3s installer.
log "installing single-node k3s ${K3S_VERSION}"
log "INSTALL_K3S_EXEC=server ${flags}"
$SUDO env \
  INSTALL_K3S_VERSION="${K3S_VERSION}" \
  INSTALL_K3S_EXEC="server ${flags}" \
  K3S_INSTALL_URL="${K3S_INSTALL_URL}" \
  sh -c 'curl -sfL "$K3S_INSTALL_URL" | sh -'

# --- make kubectl usable for this user ---------------------------------------
# The kubeconfig is world-readable (mode above), so this needs no privileges.
if [ -r /etc/rancher/k3s/k3s.yaml ]; then
  mkdir -p "${HOME}/.kube"
  install -m 600 /etc/rancher/k3s/k3s.yaml "${HOME}/.kube/config"
  log "wrote ${HOME}/.kube/config"
fi

log "done — k3s is running as a systemd service."
log "try:  kubectl get nodes        (k3s installs the kubectl symlink for you)"
