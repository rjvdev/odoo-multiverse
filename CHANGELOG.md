# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Demo GIF in both READMEs, recorded with [vhs](https://github.com/charmbracelet/vhs) from `docs/demo.tape`: the full workflow on Odoo 19 (`up`, `status`, `link`, a `psql` query on the demo data, `unlink`, `down`).
- Dependabot keeps the GitHub Actions used by the CI up to date (weekly).

### Changed

- CI: the end-to-end test runs on Odoo 16 and 20 (matrix). The required `e2e` check now aggregates both versions.
- CI: pin the runners to `ubuntu-24.04` instead of `ubuntu-latest`, so the upcoming switch of `ubuntu-latest` to Ubuntu 26 cannot break the build unannounced.

## [1.0.0] - 2026-11-12

### Added

- Docker Compose stack: one shared Postgres 16 and one service per Odoo version (16 to 20), enabled by profiles, ports bound to `127.0.0.1:8016` to `8020`, healthcheck on `/web/health`.
- `odoomv` control script: `up`, `down`, `restart`, `init`, `install`, `update`, `test`, `link`, `unlink`, `shell`, `psql`, `logs`, `src`, `trace`, `status`.
- Multi-version arguments for `up`, `down`, `restart` and `src` (`odoomv down 17 18 19`), with every version validated before anything runs.
- New `restart` command: restarts the running versions, skips the others.
- Demo data loaded by default on every version (`--with-demo` added for 19 and 20), `init --no-demo` for an empty database.
- Disposable test databases: `odoomv test <v> <module>` runs in `scratch<v>_<module>`, prints an `OK` / `FAIL` verdict with a reliable exit code, and always drops the database and its filestore.
- Guard rails: `install` and `update` only accept the `odoo<v>` and `scratch<v>_*` databases.
- Linked modules: `odoomv link` copies a module from another project, and `install`, `update` and `test` resync it automatically.
- `odoomv src` copies the Odoo source code from the image, `odoomv trace` runs the agent-skills `odoo_trace.py` helper against it.
- `lab_selftest` module for each version, using `ir.access` in Odoo 20.
- `CLAUDE.md` agent guide and `odoo-lab` Claude Code skill, installable as a plugin.
- CI: shellcheck and an end-to-end test on Odoo 16.

[Unreleased]: https://github.com/rjvdev/odoo-multiverse/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rjvdev/odoo-multiverse/releases/tag/v1.0.0
