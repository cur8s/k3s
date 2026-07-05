# Example: k3s

Installs single-node [k3s](https://k3s.io/) from the vendor's install
script, layered on the baseline. This is the technique demo for the future
`cur8s.k3s` collection — the pattern for software whose blessed install
path is `curl | sh`.

Techniques demonstrated:

- **Vendor installer piped to `sh`, made idempotent** — the naive
  `curl -sfL https://get.k3s.io | sh -` runs (and restarts the service) on
  every play. The wrapper resolves the release channel's latest version
  (the channel URL 302-redirects to the release tag — the same authority
  the installer uses) and runs the script only when the installed version
  differs. Re-runs are true no-ops; channel updates apply automatically on
  the next run.
- **Installer parameters via environment variables** (`INSTALL_K3S_CHANNEL`)
  rather than editing the piped script.
- **Declarative runtime config, separate from install mechanics** —
  `/etc/rancher/k3s/config.yaml` (Traefik disabled, kubeconfig mode) is
  written before install and restart-on-change; the systemd unit stays a
  bare `k3s server`. This is the "clean model" from the k3s research repo.
- **Readiness, not just activity** — `kubectl wait --for=condition=Ready`
  rather than `systemctl is-active`; a k3s service can be active long
  before the node can schedule anything.

Run against the local lab VM (`mise run qemu:up` first — see the
developer guide):

```sh
mise run qemu:test:k3s
```

The first play enforces the baseline (RFC-001); the second installs k3s.
Run it twice: the second run should report `changed=0` end to end.

Uninstall (the installer ships it): `sudo /usr/local/bin/k3s-uninstall.sh`.
