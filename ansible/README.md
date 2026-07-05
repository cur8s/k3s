# Parked Ansible playbooks from cur8s/ubuntu

These four directories were copied verbatim from the `examples/` catalog
of github.com/cur8s/ubuntu at commit
`14bc850e6e28d0de16fc1bfaa4617dacb4c20928` (2026-07-05), when that repo
trimmed its promised example catalog to docker/zot/tailscale ahead of
its 1.0 release. Each was proven on the QEMU lab as of that commit
(run twice, second pass `changed=0`); none is maintained here yet.

Every `site.yml` starts by enforcing the `cur8s.ubuntu` baseline and
then applies its layer — the composition pattern is documented in that
repo's user guide.

Intended disposition, to pick up after cur8s/ubuntu ships:

- `k3s/` — seed material for this repo's evolution into the k3s
  dialtone product. It already implements the config.yaml model this
  repo's README describes as its next step (channel `v1.35`, traefik
  disabled, declarative `/etc/rancher/k3s/config.yaml`, node-Ready
  wait), as an idempotent wrap of the get.k3s.io installer.
- `osquery/`, `lynis/`, `postgres/` — waiting for the environment
  repository (fleet inventory + site policy); move them there when it
  exists.
