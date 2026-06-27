# k3s

One script to install single-node [k3s](https://k3s.io) on an Ubuntu VM.
Everything is hard-coded for simplicity:

- tracks the `stable` release channel
- Traefik disabled (bring your own ingress)

## Usage

```bash
git clone <this-repo> && cd k3s
./install.sh                      # you'll be prompted for your sudo password
sudo k3s kubectl get nodes
```

To change the version or server flags, edit the env vars at the top of
`install.sh`.

## Uninstall

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```
