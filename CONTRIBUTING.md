# Contributing to odoo-multiverse

Thanks for your interest! Bug reports, fixes, documentation and ideas are all welcome.

## Before you start

- For anything bigger than a small fix, open an issue first so we can agree on the approach.
- Be kind and constructive: this project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
- Security issues must not be reported in public issues: see [SECURITY.md](SECURITY.md).

## Development setup

Requirements: Docker Engine with Compose v2, bash, rsync, [shellcheck](https://www.shellcheck.net/).

```sh
git clone https://github.com/rjvdev/odoo-multiverse ~/odoo-multiverse
cd ~/odoo-multiverse
./odoomv up 16
./odoomv init 16
```

## Checks before opening a pull request

1. `shellcheck odoomv` passes with no warning.
2. `./odoomv test 16 lab_selftest` ends with `OK: 2 tests, 0 failed, 0 error(s)`.
3. If your change touches modules, access rights, demo data or anything version-specific, also run `./odoomv test 20 lab_selftest` (20 is the version that differs most). Mention in the pull request which versions you tested.
4. Update `CLAUDE.md` and the README (both `README.md` and `README.fr.md`) when you change a command or its behavior. Agents rely on `CLAUDE.md`.
5. Add a line under `[Unreleased]` in `CHANGELOG.md`.

The CI runs shellcheck and an end-to-end test (`up 16`, `init 16`, health check, `test 16 lab_selftest`) on every pull request.

## Guidelines

- Keep `odoomv` a single, dependency-free bash script. `set -euo pipefail` stays on.
- Every command that touches a database must keep the guard rails: only `odoo<v>` and `scratch<v>_*`.
- Ports stay bound to `127.0.0.1`.
- Messages, code comments and documentation are in English (`README.fr.md` is the French translation of the README).

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add restart command
fix: keep the scratch database name check in cleanup
docs: explain WSL2 setup
ci: cache the Odoo image
```

## Pull requests

- Branch from `main` and open the pull request against `main`.
- `main` is protected: the `shellcheck` and `e2e` checks must pass before merging.
- Keep pull requests focused: one topic per pull request.
