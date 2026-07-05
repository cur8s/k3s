# Example: Lynis

Installs [Lynis](https://cisofy.com/lynis/) from the CISOfy apt repository
for manual, operator-driven security audits, layered on the baseline.

Techniques demonstrated:

- **The classic keyring dance** — some vendors ship an ASCII-armored key
  and a plain `.list` repo line (contrast with the deb822 `.sources` style
  in the docker/postgres examples): download the key, `gpg --dearmor` it
  into `/usr/share/keyrings/`, reference it with `signed-by=`.
- **Idempotent dearmoring** — `gpg --dearmor` is a command, not a state
  module, so change is computed from the downloaded key's change status
  plus a keyring `stat`.
- **A package with no service** — Lynis is a tool you run, not a daemon;
  nothing to enable or start.

Run against the local lab VM (`mise run qemu:up` first — see the
developer guide):

```sh
mise run qemu:test:lynis
```

Then audit by hand: `mise run ssh:sysadmin`, `sudo lynis audit system`.

The first play enforces the baseline (RFC-001); the second installs
Lynis. Run it twice: the second run should report `changed=0` end to end.
