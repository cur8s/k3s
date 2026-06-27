# k3s

One script to install single-node [k3s](https://k3s.io) on an Ubuntu VM.
Everything is hard-coded for simplicity:

- pinned to `v1.36.2+k3s1`
- Traefik disabled (bring your own ingress)
- world-readable kubeconfig (`kubectl` works without `sudo`)

## Usage

```bash
git clone <this-repo> && cd k3s
./install.sh          # you'll be prompted for your sudo password
kubectl get nodes
```

To change the version or server flags, edit the two values in `install.sh`.

## Uninstall

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```
