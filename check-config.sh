#!/usr/bin/env bash
# Print host Linux details, then run k3s' built-in kernel/config checks.
set -euo pipefail

K3S_BIN="/usr/local/bin/k3s"

print_header() {
  printf '\n== %s ==\n' "$1"
}

print_header "Linux host"

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  printf '  distro:        %s\n' "${PRETTY_NAME:-unknown}"
  printf '  distro id:     %s\n' "${ID:-unknown}"
  printf '  version id:    %s\n' "${VERSION_ID:-unknown}"
else
  printf '  distro:        /etc/os-release not found\n'
fi

printf '  kernel:        %s\n' "$(uname -r)"
printf '  kernel name:   %s\n' "$(uname -s)"
printf '  architecture:  %s\n' "$(uname -m)"

if [[ -r /proc/version ]]; then
  printf '  linux version: %s\n' "$(cat /proc/version)"
fi

print_header "k3s check-config"

if [[ ! -x "$K3S_BIN" ]]; then
  printf 'ERROR: k3s binary not found or not executable at %s\n' "$K3S_BIN" >&2
  printf 'Run sudo ./install-or-update.sh first.\n' >&2
  exit 1
fi

"$K3S_BIN" check-config
