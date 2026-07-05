# Example: PostgreSQL

Installs a specific PostgreSQL major version from the PGDG (PostgreSQL
Global Development Group) apt repository, layered on the baseline.

Techniques demonstrated:

- **Vendor apt repository, deb822 style** — like the docker example, but
  with the keyring in PGDG's documented location
  (`/usr/share/postgresql-common/pgdg/`) rather than `/etc/apt/keyrings/`.
- **Versioned vendor package** — `postgresql-18` pins the major version at
  install; PGDG carries every supported major side by side, which is the
  reason to use it over Ubuntu's archive.
- **Service enable/start with in-play validation.**

Run against the local lab VM (`mise run qemu:up` first — see the
developer guide):

```sh
mise run qemu:test:postgres
```

The first play enforces the baseline (RFC-001); the second installs
PostgreSQL. Run it twice: the second run should report `changed=0` end to
end. Change `postgres_version` at the top of `site.yml` to select a
different major.
