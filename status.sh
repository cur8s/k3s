#!/usr/bin/env bash
# Print a read-only status report for this single-node k3s install.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  cat >&2 <<EOF
ERROR: status.sh must be run as root.

k3s is configured with a root-only admin kubeconfig, and key state under
/var/lib/rancher/k3s is owned by root. Run:

  sudo ./status.sh
EOF
  exit 1
fi

INSTALL_K3S_BIN_DIR="/usr/local/bin"
K3S_BIN="${INSTALL_K3S_BIN_DIR}/k3s"
K3S_DATA_DIR="/var/lib/rancher/k3s"
K3S_CONFIG_DIR="/etc/rancher/k3s"
K3S_KUBECONFIG="${K3S_CONFIG_DIR}/k3s.yaml"
K3S_SERVICE="/etc/systemd/system/k3s.service"
K3S_SERVICE_ENV="/etc/systemd/system/k3s.service.env"
K3S_SQLITE_DB="${K3S_DATA_DIR}/server/db/state.db"
K3S_UNINSTALL="${INSTALL_K3S_BIN_DIR}/k3s-uninstall.sh"
K3S_KILLALL="${INSTALL_K3S_BIN_DIR}/k3s-killall.sh"

print_header() {
  printf '\n== %s ==\n' "$1"
}

print_path() {
  local label="$1"
  local path="$2"

  if [[ -e "$path" ]]; then
    printf '  %-20s %s [present]\n' "$label:" "$path"
  else
    printf '  %-20s %s [missing]\n' "$label:" "$path"
  fi
}

print_cli() {
  local name="$1"
  local path="$2"
  shift 2

  printf '  %-10s %s' "${name}:" "$path"

  if [[ ! -e "$path" ]]; then
    local path_cmd
    path_cmd="$(command -v "$name" 2>/dev/null || true)"

    if [[ -n "$path_cmd" ]]; then
      printf ' [missing; found in PATH at %s]\n' "$path_cmd"
      path="$path_cmd"
    else
      printf ' [missing]\n'
      return
    fi
  elif [[ -L "$path" ]]; then
    printf ' [symlink -> %s]\n' "$(readlink "$path")"
  else
    printf ' [present]\n'
  fi

  if [[ ! -x "$path" ]]; then
    printf '    version: not executable\n'
    return
  fi

  local output
  if output="$("$path" "$@" 2>&1)"; then
    printf '%s\n' "$output" | sed 's/^/    /'
  else
    printf '    version command failed:\n'
    printf '%s\n' "$output" | sed 's/^/      /'
  fi
}

run_or_note() {
  local note="$1"
  shift

  if "$@"; then
    return 0
  fi

  printf '  %s\n' "$note"
}

print_header "k3s status"

if command -v systemctl >/dev/null 2>&1; then
  run_or_note "systemctl could not read k3s status" \
    systemctl --no-pager --plain status k3s
else
  printf '  systemctl not found; this report is intended for Ubuntu hosts using systemd.\n'
fi

print_header "Version"

if [[ -x "$K3S_BIN" ]]; then
  "$K3S_BIN" --version
elif command -v k3s >/dev/null 2>&1; then
  k3s --version
else
  printf '  k3s binary not found.\n'
fi

print_header "Command-line tools"
print_cli "k3s" "${INSTALL_K3S_BIN_DIR}/k3s" --version
print_cli "kubectl" "${INSTALL_K3S_BIN_DIR}/kubectl" version --client=true
print_cli "crictl" "${INSTALL_K3S_BIN_DIR}/crictl" --version
print_cli "ctr" "${INSTALL_K3S_BIN_DIR}/ctr" --version
print_path "killall script" "$K3S_KILLALL"
print_path "uninstall script" "$K3S_UNINSTALL"

print_header "Cluster"

if [[ -r "$K3S_KUBECONFIG" ]]; then
  if [[ -x "$K3S_BIN" ]]; then
    run_or_note "kubectl could not read node status" \
      "$K3S_BIN" kubectl get nodes -o wide
  elif command -v k3s >/dev/null 2>&1; then
    run_or_note "kubectl could not read node status" \
      k3s kubectl get nodes -o wide
  else
    printf '  k3s binary not found.\n'
  fi
else
  printf '  kubeconfig is missing or not readable: %s\n' "$K3S_KUBECONFIG"
fi

print_header "Key paths"
print_path "binary" "$K3S_BIN"
print_path "config dir" "$K3S_CONFIG_DIR"
print_path "kubeconfig" "$K3S_KUBECONFIG"
print_path "data dir" "$K3S_DATA_DIR"
print_path "sqlite db" "$K3S_SQLITE_DB"
print_path "systemd unit" "$K3S_SERVICE"
print_path "systemd env" "$K3S_SERVICE_ENV"
print_path "killall script" "$K3S_KILLALL"
print_path "uninstall script" "$K3S_UNINSTALL"

print_header "Useful commands"
printf '  Check nodes:       sudo k3s kubectl get nodes -o wide\n'
printf '  Check host config: ./check-config.sh\n'
printf '  Service logs:      sudo journalctl -u k3s -f\n'
printf '  Restart service:   sudo systemctl restart k3s\n'
printf '  Update k3s:        sudo ./install-or-update.sh\n'
printf '  Uninstall k3s:     sudo %s\n' "$K3S_UNINSTALL"
