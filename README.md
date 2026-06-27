# k3s

One script to install single-node [k3s](https://k3s.io) on an Ubuntu VM.
Everything is hard-coded for simplicity:

- tracks the `stable` release channel
- Traefik disabled (bring your own ingress)
- records the install, config, kubeconfig, and data paths in `install-or-update.sh`

## Usage

```bash
git clone <this-repo> && cd k3s
./install-or-update.sh            # you'll be prompted for your sudo password
sudo k3s kubectl get nodes
./status.sh
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
./status.sh
sudo ./status.sh                  # includes node status when kubeconfig is root-only
```

## Uninstall

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```
