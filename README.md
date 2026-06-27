# k3s

One script to install single-node [k3s](https://k3s.io) on an Ubuntu VM.
Everything is hard-coded for simplicity:

- tracks the `v1.35` release channel for latest Kubernetes v1.35 patches
- Traefik disabled (bring your own ingress)
- records the install, config, kubeconfig, and data paths in `install-or-update.sh`

## Release channel philosophy

This repo tracks a Kubernetes minor release channel, currently `v1.35`, instead
of the generic `stable` channel.

That means rerunning `sudo ./install-or-update.sh` picks up the latest k3s patch
release for Kubernetes v1.35, but does not intentionally move the node to the
next Kubernetes minor release. This keeps routine patching predictable while
avoiding surprise Kubernetes upgrades from `v1.35` to `v1.36`.

When you are ready to move to a newer Kubernetes minor release, update
`INSTALL_K3S_CHANNEL` in `install-or-update.sh`, review the Kubernetes/k3s
release notes, then rerun the installer.

## Usage

```bash
git clone <this-repo> && cd k3s
sudo ./install-or-update.sh
sudo k3s kubectl get nodes
sudo ./status.sh
```

To change the version or server flags, edit the env vars at the top of
`install-or-update.sh`.

## Where k3s writes files

The installer records these defaults in `install-or-update.sh` before invoking the
official k3s install script:

| Purpose | Env var | Default |
| --- | --- | --- |
| k3s binary, helper symlinks, uninstall script | `INSTALL_K3S_BIN_DIR` | `/usr/local/bin` |
| k3s state/data directory | `K3S_DATA_DIR` | `/var/lib/rancher/k3s` |
| admin kubeconfig | `K3S_KUBECONFIG_OUTPUT` | `/etc/rancher/k3s/k3s.yaml` |
| admin kubeconfig file mode | `K3S_KUBECONFIG_MODE` | `0600` |

Useful files and directories after install:

- `/etc/rancher/k3s/` - k3s config directory and root-readable admin kubeconfig
- `/var/lib/rancher/k3s/` - cluster state, containerd data, kubelet data, and local storage
- `/var/lib/rancher/k3s/server/db/state.db` - default single-node SQLite datastore
- `/etc/systemd/system/k3s.service` - systemd service
- `/etc/systemd/system/k3s.service.env` - environment persisted by the installer
- `/usr/local/bin/k3s-uninstall.sh` - uninstall script

## Status report

```bash
sudo ./status.sh
```

## Uninstall

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```
