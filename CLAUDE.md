# odoo-multiverse: agent guide

This lab runs, initializes, tests and reads the code of Odoo 16 to 20 side by side. It has one shared Postgres server and one Docker service per version, enabled by a profile. Everything goes through the `./odoomv` script.

## Layout

```
compose.yml        db (postgres:16, no profile) + odoo16 … odoo20 (profiles "16" … "20"), with healthchecks
odoomv             control script (single entry point)
addons/<v>/        modules under development, mounted at /mnt/extra-addons in odoo<v>
src/<v>/odoo/      Odoo source code copied from the image (read-only, via `odoomv src`)
skills/odoo-lab/   Claude Code skill to use the lab from another project
.claude-plugin/    manifests to install that skill as a plugin
```

## Versions, ports, databases

| Version | Service | URL | Work database | Test databases |
|---|---|---|---|---|
| 16 | odoo16 | http://127.0.0.1:8016 | odoo16 | scratch16_* |
| 17 | odoo17 | http://127.0.0.1:8017 | odoo17 | scratch17_* |
| 18 | odoo18 | http://127.0.0.1:8018 | odoo18 | scratch18_* |
| 19 | odoo19 | http://127.0.0.1:8019 | odoo19 | scratch19_* |
| 20 | odoo20 | http://127.0.0.1:8020 | odoo20 | scratch20_* |

- Ports are bound to 127.0.0.1 only.
- Odoo credentials: `admin` / `admin`. Postgres: `odoo` / `odoo`. The Postgres port is not exposed: use `odoomv psql`.
- Each instance has `--db-filter=^(odoo<v>|scratch<v>_.*)$` and its own filestore (volume `odoo<v>-data`).
- Each Odoo service has a healthcheck on `/web/health`: `odoomv status` shows `(healthy)` once Odoo answers.
- Messages show paths under `$HOME` as `~/…`. When odoomv starts Postgres or a one-off container implicitly, Compose progress output is hidden (errors are still printed).

## Commands

`<v>` is 16, 17, 18, 19 or 20 (`16.0` is accepted). `up`, `down`, `restart` and `src` take several versions; every version is validated before anything runs.

| Command | Effect |
|---|---|
| `./odoomv up <v>...` | `docker compose --profile <v> up -d` (db and odoo<v>) for each version |
| `./odoomv down [<v>...]` | Stops and removes the odoo<v> containers. A version that is not running is not an error. No argument: stops the whole lab. Volumes are kept. |
| `./odoomv restart <v>...` | Restarts odoo<v> if it is running, otherwise prints "skipped" |
| `./odoomv init <v> [--demo\|--no-demo]` | Creates the `odoo<v>` database with `base` installed, then restarts odoo<v> if it is running. Refuses if the database already exists. |
| `./odoomv install <v> <mods> [db]` | `-i <mods>` on `odoo<v>` (default), then restarts odoo<v> if it is running |
| `./odoomv update <v> <mods> [db]` | `-u <mods>` on `odoo<v>` (default), then restarts odoo<v> if it is running |
| `./odoomv test <v> <module>` | Tests the module in a disposable `scratch<v>_<module>` database |
| `./odoomv link <v> <path>` | Copies (`rsync -a --delete`) a module from another project into `addons/<v>/<module>` and records the source in `addons/<v>/.links` |
| `./odoomv unlink <v> <module>` | Removes the copy of a linked module and its `.links` entry. The source is untouched and the module stays installed in the databases. |
| `./odoomv shell <v> [db]` | `odoo shell`. Accepts a script on stdin: `./odoomv shell 16 < script.py` |
| `./odoomv psql <v> [db]` | `docker compose exec db psql -U odoo <db>` (`odoo<v>` by default). Accepts SQL on stdin. |
| `./odoomv logs <v> [-f]` | Last 200 lines of the odoo<v> service, `-f` to follow |
| `./odoomv src <v>... [--force]` | Copies the `odoo` package of the `odoo:<v>.0` image into `src/<v>/odoo` (`docker cp`) |
| `./odoomv trace <v> <args...>` | Runs `odoo_trace.py` (agent-skills:odoo-workflow, most recent version in the plugin cache) on `src/<v>` + `addons/<v>`. Example: `./odoomv trace 16 field sale.order commitment_date`. Requires `odoomv src <v>`. Helper exit code: 0 FOUND, 1 NOT FOUND, 2 error. Does not need Docker. |
| `./odoomv status` | Containers, existing databases, ports |

`init`, `install`, `update`, `test` and `shell` run in a disposable container (`docker compose --profile <v> run --rm odoo<v> … --stop-after-init --no-http`). The running web instance is never touched.

### Linked modules (`link` / `unlink`)

Modules from other projects are not mounted directly: `link` makes a copy in `addons/<v>/<module>` (without `.git/`, `__pycache__/` or `*.pyc`).

- The source must contain a `__manifest__.py`. The module name is the name of the source folder and must match `[a-z0-9_]+`.
- The destination is always exactly `addons/<v>/<module>`. `link` refuses to overwrite a lab module that is not linked (for example `lab_selftest`), and a source already inside `addons/<v>`.
- Running `link` again on a linked module resyncs the copy. If the source changed, it is replaced.
- **`install`, `update` and `test` resync the listed linked modules automatically** before starting Odoo. Linked dependencies that are not listed are not resynced: list them too (`install 16 mod_a,mod_b`).
- `addons/<v>/.links` (format `module<TAB>path`) is ignored by Git. The copies are listed in `addons/<v>/.gitignore`, so that another project's code is never committed.
- No automatic removal: linked modules stay in place until an explicit `unlink`.

### Demo data

Odoo changed its default behavior in version 19. The script makes it consistent: **demo data is loaded by default on every version**.

| Version | Native Odoo behavior | `init` (default / `--demo`) | `init --no-demo` |
|---|---|---|---|
| 16–18 | demo loaded by default | nothing added | `--without-demo=all` |
| 19–20 | demo not loaded by default | `--with-demo` | nothing added |

`odoomv test` always loads demo data, since many tests depend on it.

### `odoomv test` in detail

1. Drops `scratch<v>_<module>` if it exists.
2. Installs the module with `--test-enable --test-tags /<module> --log-level=test`.
3. Fails (exit code ≠ 0) in three cases: no `N failed, M error(s) of K tests` line with K > 0; a non-zero `failed` or `error(s)` value; a non-zero Odoo exit code.
4. Always drops the database and its filestore, even on failure or interruption (`trap EXIT`).
5. Writes the full Odoo log to `logs/test-<v>-<module>-<timestamp>.log` (`logs/` is ignored by Git).

The last line is the verdict, with the path of the log: `OK: N tests, 0 failed, 0 error(s) (log: logs/…)` or `FAIL: <reasons> (log: logs/…)`.

### `odoomv trace` sentinels

Quick check that `trace` targets the right version (checked on 2026-11-12, cross-checked with grep in `src/<v>`):

| Command | 16 | 17 | 18 | 19 | 20 |
|---|---|---|---|---|---|
| `trace <v> env` | Odoo 16.0 | Odoo 17.0 | Odoo 18.0 | Odoo 19.0 | Odoo 20.0 |
| `trace <v> field sale.order commitment_date` | FOUND | FOUND | FOUND | FOUND | FOUND |
| `trace <v> method res.partner name_get` | FOUND | FOUND | NOT FOUND | NOT FOUND | NOT FOUND |
| `trace <v> model res.groups.privilege` | NOT FOUND | NOT FOUND | NOT FOUND | FOUND | FOUND |

If `env` does not print `Odoo <v>.0`, do not trust the other verdicts: run `odoomv src <v> --force` again.

### Version differences worth knowing

- **Access rights in 20**: `ir.model.access` no longer exists. It is replaced by `ir.access`, which also absorbs `ir.rule`. File `security/ir.access.csv`, columns `id,name,model_id,group_id/id,operation,domain`, with `model_id` given as the model name and `operation` as letters from `crud`. An `ir.model.access.csv` makes the installation crash (`KeyError: 'ir.model.access'`). See `addons/20/lab_selftest`.
- **Test count in 20**: `odoomv test 20 <module>` also counts 2 cross-module JS suites from `web` (`WebSuite`, `MobileWebSuite`), empty for a module without JS. Example: lab_selftest reports 4 tests for 2 Python methods.
- **Images 19 and 20**: the package contains two copies of the addons (`odoo/addons` and `addons`). `odoo/addons`, which `odoomv src` copies, is the superset (`base` + `test_*`) and Odoo loads it first.

## Rules for an agent

- **Never install or update on a database other than `odoo<v>` or `scratch<v>_*`.** The script refuses other names: do not work around it with `docker compose` or `odoo-bin` directly.
- Always go through `./odoomv`. Never install or update a module from the Apps menu: the HTTP worker has memory and time limits and can leave the module state inconsistent.
- Run tests only with `./odoomv test`, never on `odoo<v>`. Check the final verdict (`OK: N tests…`).
- Develop the lab's own modules in `addons/<v>/<module>/`. For a module from another project, use `./odoomv link` and edit **the source**, never the copy: it is overwritten at each resync. Run `./odoomv update <v> <module>` after each change to Python, XML or the manifest.
- Do not `unlink` a module you did not link yourself in the session without asking the user.
- To find where a model, field or method is defined, run `./odoomv src <v>` once, then `./odoomv trace <v> model|field|method|xmlid|depends …`, which gives a verdict and `file:line`. In 16/17 the helper warns that its rules are only verified on 18/19: check a doubtful verdict with `grep` in `src/<v>/odoo`. Never modify `src/`: it is a reference copy, not the running code.
- To inspect the database, use `./odoomv psql <v>` (read). For the ORM, `./odoomv shell <v> < script.py`, with `env.cr.rollback()` at the end of the script if it must not write.
- `./odoomv down` without argument stops the whole lab. Do not remove the volumes (`docker compose down -v`) without an explicit request: that erases every database.

## Design choices and known pitfalls

Each line gives the problem, then the rule that was kept:

- **Trap reading local variables**: a `trap cleanup EXIT` set inside a function reads `$db` and `$log`, which no longer exist on exit. `set -u` then makes the cleanup crash and the database stays. → Pass the values to the trap when setting it: `trap "cleanup_test $(printf '%q ' …)" EXIT`, to a global function that checks the database name again (`^scratch<v>_…$`).
- **`set -e` inside `$(...)`**: bash does not inherit `set -e` in command substitutions, so a failing check inside a function called as `$(...)` does not stop it. → Add an explicit `|| exit 1` there (see `parse_versions`).
- **Docker group not active yet**: "permission denied … docker.sock" although the user is in the `docker` group, because the session was opened before the change. → Prefix with `sg docker -c "…"` or open a new session. Do not touch the socket permissions.
- **`.claude/odoo.json` vs `--version`**: if a `.claude/odoo.json` declares a version, `odoo_trace.py` stops with SETUP ERROR ("version sources disagree") on the other versions. → `odoomv trace` always passes `--version <v>.0` with `--odoo-root` and `--addons`.
- **Ports exposed on every interface**: a port published as `"8016:8069"` is open to the whole network. → Always bind to the local machine: `"127.0.0.1:80<v>:8069"`.
- **Scratch databases shared across versions**: a `scratch_<module>` name collides from one version to another on the shared Postgres. → Prefix with the version (`scratch<v>_<module>`) and filter with `--db-filter=^(odoo<v>|scratch<v>_.*)$`.
- **`A && B || C` as if/else**: `docker cp … && docker rm … || { … die }` reports a cp failure when `docker rm` is what failed, and removes the container twice (shellcheck SC2015). → Capture the code (`|| rc=$?`), clean up, then test `rc`.
- **Module not portable to 20**: a module copied as is from 16 crashes in 20 (`KeyError: 'ir.model.access'`). → Before calling a module "compatible", test it with `odoomv test <v>` on every target version. Access rights change format in 20.
- **Anonymous volumes left by `docker create`**: the Odoo image declares `VOLUME`s, and `docker rm` without `-v` leaves them behind. → `docker rm -v` for any temporary container created with `docker create`.
