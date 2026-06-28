# k3s

One script to install single-node [k3s](https://k3s.io) on an Ubuntu VM.
Everything is hard-coded for simplicity:

- tracks the `v1.35` release channel for latest k3s releases on Kubernetes v1.35
- Traefik disabled (bring your own ingress)
- records the install, config, kubeconfig, and data paths in `install-or-update.sh`

## Release channel philosophy

This repo tracks a Kubernetes minor release channel, currently `v1.35`, instead
of the generic `stable` channel.

That means rerunning `sudo ./install-or-update.sh` picks up the latest k3s
release available for Kubernetes v1.35, but does not intentionally move the node
to the next Kubernetes minor release. This keeps routine patching predictable
while avoiding surprise Kubernetes upgrades from `v1.35` to `v1.36`.

When you are ready to move to a newer Kubernetes minor release, update
`INSTALL_K3S_CHANNEL` in `install-or-update.sh`, review the Kubernetes/k3s
release notes, then rerun the installer.

## K3s packaging model

k3s is Kubernetes, not a lightweight fork or a separate Kubernetes
implementation. It uses the same upstream Kubernetes projects for core
components such as the API server, scheduler, controller manager, and kubelet.

The main difference is packaging. k3s ships most of the distribution as a
single `k3s` executable. Components that can run as Go libraries are linked into
that process, while lower-level runtime tools remain standalone binaries that
are embedded inside the `k3s` executable.

Conceptually, a single-node server looks like this:

```text
systemd
  \_ k3s
       |- API server
       |- scheduler
       |- controller manager
       |- kubelet
       `- embedded containerd
```

Runtime tools that need to behave like normal Linux executables are extracted on
disk under a versioned data directory:

```text
/var/lib/rancher/k3s/data/<release-hash>/bin/
```

That extracted runtime area contains tools such as `containerd`, `runc`,
`containerd-shim-runc-v2`, `ctr`, and `kubectl`. Separately, the official
installer places the main `k3s` binary in `/usr/local/bin` and may create helper
symlinks there for `kubectl`, `crictl`, and `ctr`.

The `/usr/local/bin/k3s` executable is also a multicall binary. A multicall
binary is one executable that exposes several command personalities. The command
it runs can be selected by an explicit subcommand:

```bash
sudo k3s kubectl get nodes
sudo k3s crictl ps
sudo k3s ctr --version
```

It can also be selected by the name used to invoke the executable. That is why
the installer can create symlinks like this:

```text
/usr/local/bin/kubectl -> k3s
/usr/local/bin/crictl  -> k3s
/usr/local/bin/ctr     -> k3s
```

When `/usr/local/bin/kubectl` is a symlink to `/usr/local/bin/k3s`, running
`kubectl get nodes` still starts the same `k3s` binary. The binary sees that it
was invoked as `kubectl` and dispatches to its kubectl behavior. This is the
same general pattern used by tools like BusyBox: one physical executable can
serve multiple command names.

That multicall behavior is separate from the extracted runtime binaries under
`/var/lib/rancher/k3s/data/<release-hash>/bin/`. The symlinks in
`/usr/local/bin` are convenience entrypoints into `k3s`; the extracted files are
the runtime tools k3s uses internally to run containers.

This packaging model is why k3s can be small without being a different
Kubernetes. The Kubernetes components share one Go runtime and one copy of the
linked Kubernetes libraries instead of being shipped as many separate binaries
with duplicated code.

The embedded container runtime also explains the update behavior. k3s manages
containerd, and containerd manages per-container shim processes. Those shim
processes are what keep containers attached to the host while containerd or k3s
restarts. When k3s comes back, containerd reconnects to the existing shims and
resumes managing the running containers.

## Update behavior

This repo updates k3s by rerunning the official k3s install script with the
same environment variables used for install:

```bash
sudo ./install-or-update.sh
```

For this repo, that means:

- the installer resolves `INSTALL_K3S_CHANNEL=v1.35` to the latest k3s release
  available for Kubernetes v1.35
- the k3s binary under `/usr/local/bin/k3s` is installed or replaced if needed
- the systemd service and environment files under `/etc/systemd/system/` are
  created or refreshed
- the `k3s-killall.sh` and `k3s-uninstall.sh` scripts are created or refreshed
- the `kubectl`, `crictl`, and `ctr` helper symlinks are created only when those
  commands are not already found in `PATH`
- the existing data directory stays at `/var/lib/rancher/k3s`
- the existing admin kubeconfig stays at `/etc/rancher/k3s/k3s.yaml`
- the k3s systemd service is restarted when the installed binary or service
  configuration changes

The important single-node workload behavior is documented in the
[k3s manual upgrade docs](https://docs.k3s.io/upgrades/manual): the install
script does not cordon or drain the node, and k3s pod containers continue
running while the k3s service restarts.

So, in normal update conditions, running pods are not intentionally stopped or
restarted by `sudo ./install-or-update.sh`. The k3s process restarts, but the
workload containers should keep running.

Why that works:

```text
systemd
  \_ k3s
       \_ embedded containerd
            \_ containerd-shim-runc-v2
                 \_ workload container
```

k3s starts and supervises its embedded containerd. containerd is responsible for
creating containers, but it does not stay as the direct parent of each running
container. For each container, containerd creates a shim process. The shim keeps
the container connected to the host, owns the container process, and preserves
the container's stdio and exit status.

During a normal k3s service restart, the k3s process and its embedded containerd
go away temporarily. The shim processes and the workload containers remain
running. When k3s starts again, embedded containerd reconnects to the existing
shim processes and resumes managing those containers. That is the mechanism
behind the k3s docs statement that pod containers continue running while k3s is
stopped or restarted.

This applies to a normal service restart during install/update. It is different
from running `/usr/local/bin/k3s-killall.sh` or the uninstall script, which are
maintenance/destructive operations intended to stop k3s processes and clean up
state.

This is still not the same thing as a zero-impact production upgrade:

- the Kubernetes API server is briefly unavailable while k3s restarts
- `kubectl` commands may fail during that restart window
- scheduling, controller reconciliation, rollouts, and jobs may pause briefly
- a single-node cluster has nowhere else to move workloads if the host itself
  has a problem
- pods can still restart for normal Kubernetes reasons, such as failing health
  checks or application crashes

Practical update flow:

```bash
sudo ./status.sh
sudo ./install-or-update.sh
sudo ./status.sh
sudo k3s kubectl get pods -A
```

For a personal or small single-node cluster, this is usually fine. For anything
with strict availability requirements, schedule a maintenance window and make
sure application-level backups exist before updating.

## Usage

```bash
git clone <this-repo> && cd k3s
sudo ./install-or-update.sh
sudo k3s kubectl get nodes
sudo ./status.sh
./check-config.sh
```

To change the version or server flags, edit the env vars at the top of
`install-or-update.sh`.

## Where k3s writes files

The installer records these defaults in `install-or-update.sh` before invoking the
official k3s install script:

| Purpose | Env var | Default |
| --- | --- | --- |
| k3s binary, helper symlinks, killall script, uninstall script | `INSTALL_K3S_BIN_DIR` | `/usr/local/bin` |
| k3s state/data directory | `K3S_DATA_DIR` | `/var/lib/rancher/k3s` |
| admin kubeconfig | `K3S_KUBECONFIG_OUTPUT` | `/etc/rancher/k3s/k3s.yaml` |
| admin kubeconfig file mode | `K3S_KUBECONFIG_MODE` | `0600` |

Useful files and directories after install:

- `/etc/rancher/k3s/` - k3s config directory and root-readable admin kubeconfig
- `/var/lib/rancher/k3s/` - cluster state, containerd data, kubelet data, and local storage
- `/var/lib/rancher/k3s/server/db/state.db` - default single-node SQLite datastore
- `/etc/systemd/system/k3s.service` - systemd service
- `/etc/systemd/system/k3s.service.env` - environment persisted by the installer
- `/usr/local/bin/k3s-killall.sh` - script generated by the installer to stop k3s processes
- `/usr/local/bin/k3s-uninstall.sh` - uninstall script

## Status report

```bash
sudo ./status.sh
```

## Kernel/config check

Run k3s' built-in host configuration check:

```bash
./check-config.sh
```

The script prints the Linux distribution, distro version, kernel version,
architecture, and `/proc/version` first, then invokes:

```bash
/usr/local/bin/k3s check-config
```

## Uninstall

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

## References

### K3s Internals video

- Title: [K3s Internals: The Crazy Things We Do To Make k8s Simple - w/ Darren Shepherd, Rancher Labs](https://www.youtube.com/watch?v=k58WnbKmjdA)
- Source: Civo
- Speaker: Darren Shepherd
- YouTube id: `k58WnbKmjdA`
- Released: January 13, 2021
- Uploaded: January 14, 2021
- Duration: `2:36:19`
- Transcript source: English subtitle transcript downloaded with `yt-dlp`

Chapter outline from the video metadata:

- `00:00` - Intro
- `02:06` - K3s Internals talk introduction
- `06:08` - The single binary
- `28:58` - Agent tunnel
- `41:40` - etcd management
- `1:08:00` - Agents and client-side load balancing
- `1:18:05` - CoreDNS - node DNS
- `1:22:24` - Patches
- `1:52:50` - Q&A

Transcript-derived notes relevant to this repo:

- The official install script is intentionally thin: it downloads and verifies
  the `k3s` binary, installs it, creates helper symlinks and maintenance
  scripts, writes the systemd unit, and starts `k3s server`.
- The `k3s` executable is a multicall binary. The same physical binary can act
  like `k3s`, `kubectl`, `crictl`, or `ctr` depending on the subcommand or the
  symlink name used to invoke it.
- The binary is also effectively a self-extracting distribution. On first start,
  k3s prepares `/var/lib/rancher/k3s/data/<release-hash>/` and extracts the
  runtime tools it needs under that content-addressed data directory.
- k3s tries to minimize assumptions about the host OS. The video describes k3s
  as bringing much of the required user space with it and relying mainly on a
  suitable Linux kernel and expected system mounts.
- The extracted runtime includes ordinary Linux executables such as containerd,
  runc, containerd shims, CNI utilities, BusyBox-style utilities, and support
  tools used by Kubernetes/containerd features.
- `k3s check-config` is called out as a useful host validation tool, especially
  for unusual kernels, custom Linux builds, ARM boards, or other environments
  that are less standard than a normal Ubuntu VM.
- The `k3s-killall.sh` and uninstall scripts are operational cleanup tools, not
  graceful Kubernetes workflows. They do not drain nodes or coordinate workload
  shutdown through the Kubernetes API.

The raw transcript is not copied into this README; the notes above are a
paraphrased summary of the downloaded subtitle transcript.
