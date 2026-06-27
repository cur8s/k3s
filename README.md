# k3s

One script to install single-node [k3s](https://k3s.io) on an Ubuntu VM, with
pinned, opinionated defaults:

- **pinned version** (`v1.36.2+k3s1`) — reproducible installs
- **Traefik disabled** — bring your own ingress
- **world-readable kubeconfig** — `kubectl` works without `sudo`

## Usage

```bash
git clone <this-repo> && cd k3s
./install.sh
kubectl get nodes
```

Run it as your normal user — it uses `sudo` only for the install step itself,
and drops a ready-to-use `~/.kube/config` in place.

## Configuration

Override any default via the environment:

```bash
K3S_VERSION=v1.35.1+k3s1 ./install.sh
K3S_TLS_SANS="203.0.113.10 k3s.example.com" ./install.sh   # extra API-cert SANs
K3S_DISABLE_SERVICELB=true ./install.sh                    # use MetalLB instead
```

| Variable | Default | Purpose |
|---|---|---|
| `K3S_VERSION` | `v1.36.2+k3s1` | Pinned k3s release |
| `K3S_DISABLE_TRAEFIK` | `true` | Skip the bundled Traefik ingress |
| `K3S_DISABLE_SERVICELB` | `false` | Skip the bundled Klipper ServiceLB |
| `K3S_KUBECONFIG_MODE` | `0644` | Mode for `/etc/rancher/k3s/k3s.yaml` |
| `K3S_TLS_SANS` | _(empty)_ | Extra API-cert SANs, space-separated |
| `K3S_EXTRA_FLAGS` | _(empty)_ | Raw flags appended to the k3s server |
| `K3S_INSTALL_URL` | `https://get.k3s.io` | Installer URL (override for air-gapped) |

Find versions to pin at <https://github.com/k3s-io/k3s/releases>.

## Uninstall

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```
