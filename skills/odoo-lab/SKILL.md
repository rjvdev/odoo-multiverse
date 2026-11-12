---
name: odoo-lab
description: Local multi-version Odoo lab (16 to 20) in ~/odoo-multiverse, driven by ~/odoo-multiverse/odoomv. Use it from any project to install, update or test an Odoo module on a real instance (odoomv link brings in a module from another repository), open a shell or psql, or read the official source code of a version (src/<v>) to trace a model, a method or a view.
---

# Odoo lab (~/odoo-multiverse)

The lab is a clone of the odoo-multiverse repository, expected in `~/odoo-multiverse`. If it was cloned elsewhere, replace `~/odoo-multiverse` with that path in every command below. If it is missing, tell the user instead of creating it.

Full reference: `~/odoo-multiverse/CLAUDE.md`. Read it before any unusual action.

## Principles
- One shared Postgres and one service per version: `odoo16` … `odoo20`, ports 127.0.0.1:8016 … 8020.
- Always call `~/odoo-multiverse/odoomv <command>` (absolute path, whatever the current directory). Never run `docker compose` or `odoo-bin` directly.
- Allowed databases: `odoo<v>` (work) and `scratch<v>_*` (disposable tests). Never install or update anywhere else. The script refuses other names: do not work around it.
- `up`, `down`, `restart` and `src` accept several versions (`odoomv down 17 18 19`).

## Test a module from another project
1. `~/odoo-multiverse/odoomv link <v> <path/to/module>`: copies the module (rsync) into `~/odoo-multiverse/addons/<v>/<module>`. A `__manifest__.py` is required. The module name is the folder name.
2. `~/odoo-multiverse/odoomv status`. If the service or the database is missing: `~/odoo-multiverse/odoomv up <v>`, then `~/odoo-multiverse/odoomv init <v>`.
3. `~/odoo-multiverse/odoomv test <v> <module>`: resyncs the copy, tests in `scratch<v>_<module>` (dropped afterwards), then gives the verdict on the last line (`OK: N tests…` or `FAIL: …`) with a reliable exit code.
4. To try it by hand: `~/odoo-multiverse/odoomv install <v> <module>`, then http://127.0.0.1:80<v> (admin/admin).
5. Edit **the source in the project**, never the copy in `addons/<v>/`. `install`, `update` and `test` resync the listed linked modules automatically before starting Odoo (list linked dependencies too: `mod_a,mod_b`):
   `~/odoo-multiverse/odoomv update <v> <module>`
6. No removal at the end of the work: the module stays linked. `~/odoo-multiverse/odoomv unlink <v> <module>` only on request. It removes the copy, not the source, and uninstalls nothing.

## Read Odoo's code
`~/odoo-multiverse/odoomv src <v>` once, then search in `~/odoo-multiverse/src/<v>/odoo` (addons in `odoo/addons/`). Cite as `file:line`. Never modify that folder.

## Trace code with agent-skills
`~/odoo-multiverse/odoomv trace <v> <odoo_trace.py command>` (e.g. `~/odoo-multiverse/odoomv trace 16 field sale.order commitment_date`): FOUND verdict with `file:line`, or NOT FOUND with close names. It needs the agent-skills plugin (it provides `odoo_trace.py`) and a prior `odoomv src <v>`. In 16/17, check a doubtful verdict in `src/<v>`.

The agent-skills pack only covers 16 to 19. For 20 there is no reference: rely only on `odoomv trace 20` and grep in `src/20`, and never assume that a 19 API still exists.

## Odoo 20 differences
### Access rights: `ir.access` replaces `ir.model.access` and `ir.rule`
- **Symptom**: a module ported from an earlier version makes the registry fail to load on install (`Failed to load registry`, `KeyError: 'ir.model.access'`). `odoomv test 20` answers "no test ran".
- **Cause**: in 20 the `ir.model.access` model no longer exists. `ir.access` (`base/models/ir_access.py`) replaces it and also absorbs record rules (`ir.rule`). A `security/ir.model.access.csv` therefore loads an unknown model.
- **Fix**: replace that file with `security/ir.access.csv`, declared in the manifest:
  ```
  id,name,model_id,group_id/id,operation,domain
  access_my_model_user,my.model user,my.model,base.group_user,crud,
  ```
  `model_id` takes the technical model name, `operation` letters from `crud`, and `domain` replaces the record rule (empty = all records). Use `src/20/odoo/addons/crm/security/ir.access.csv` as a model, along with the `addons/20/lab_selftest` test module. This file is not backward compatible: keep one variant per version.

## Inspect
- SQL: `echo "select …" | ~/odoo-multiverse/odoomv psql <v>`
- ORM: `~/odoo-multiverse/odoomv shell <v> < script.py`, with `env.cr.rollback()` at the end if the script must not write.
- Logs: `~/odoo-multiverse/odoomv logs <v>`

## Demo data
Loaded by default on every version with `init` (the script adds `--with-demo` in 19–20). `init --no-demo` for an empty database. `test` always loads demo data.

## Pitfalls
- Docker refuses access ("permission denied … docker.sock"): the session predates the addition to the docker group. Prefix with `sg docker -c "…"` or open a new session.
- `link` refuses to overwrite a lab module that is not linked. Do not delete that module to force it: ask the user.
- The lab does not replace staging or production: a green test here does not guarantee a risk-free update on a real database.
