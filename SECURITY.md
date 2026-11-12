# Security policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x | Yes |

## Scope

odoo-multiverse is a **local development lab**. Some choices are deliberate and are not considered vulnerabilities:

- default credentials (`admin` / `admin` for Odoo, `odoo` / `odoo` for Postgres);
- no TLS.

These are acceptable only because every port is bound to `127.0.0.1`. Anything that would expose the lab beyond the local machine, run commands outside the lab, or let `odoomv` touch a database other than `odoo<v>` or `scratch<v>_*` **is** in scope.

Vulnerabilities in Odoo itself or in the official Docker images should be reported to their maintainers, not here.

## Reporting a vulnerability

Please **do not open a public issue**. Use GitHub's private vulnerability reporting instead: open the repository's **Security** tab, then **Report a vulnerability**.

Include the steps to reproduce, the affected version (`git describe --tags`), your OS and your Docker version. You should get a first answer within a week.
