# odoo-multiverse

**Odoo 16 → 20 côte à côte. Données de démo, bases de test jetables, traçage du code source. Pensé pour les développeurs et les agents IA.**

[![CI](https://github.com/rjvdev/odoo-multiverse/actions/workflows/ci.yml/badge.svg)](https://github.com/rjvdev/odoo-multiverse/actions/workflows/ci.yml)
[![Licence : MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[English version](README.md)

## Le problème

Quand on maintient des modules Odoo, on travaille rarement sur une seule version. Un client est en 16, un autre passe en 18, et les versions 19 et 20 modifient des API sur lesquelles on comptait. Garder une installation `odoo-bin` par version oblige à jongler entre virtualenvs, versions de Python et bibliothèques système. Les bases de test s'accumulent. Vérifier qu'une méthode existe encore en 19 devient un jeu de devinettes, et les agents IA comblent les trous en devinant.

odoo-multiverse réunit les cinq versions derrière une seule commande :

- **Une seule pile** : un Postgres 16 partagé et une image officielle `odoo:<v>.0` par version, chacune sur son propre port local.
- **Données de démo partout** : chargées par défaut sur toutes les versions, y compris en 19 et 20, où Odoo les rend facultatives.
- **Bases de test jetables** : `odoomv test 18 mon_module` installe le module dans une base neuve `scratch18_mon_module`, lance ses tests, affiche un verdict clair avec un code de sortie fiable, puis supprime la base, même en cas d'échec.
- **Vos modules, d'où qu'ils viennent** : `odoomv link` copie dans le labo un module de n'importe quel dépôt, et `install`, `update` et `test` le resynchronisent automatiquement.
- **Le code source sous la main** : `odoomv src 19` copie le code exact d'Odoo livré dans l'image. Vous (ou votre agent) cherchez dans le vrai code au lieu de deviner.
- **Prêt pour les agents** : un guide `CLAUDE.md` et un skill Claude Code expliquent aux agents IA comment utiliser le labo sans risque : bases autorisées, lignes de verdict, écarts entre versions.

## Installation

Prérequis : Docker Engine avec Compose v2, bash, rsync. Python 3 n'est nécessaire que pour `odoomv trace`.

```sh
git clone https://github.com/rjvdev/odoo-multiverse ~/odoo-multiverse && ~/odoo-multiverse/odoomv up 16
```

Créez ensuite la base et vérifiez que tout fonctionne :

```sh
~/odoo-multiverse/odoomv init 16
~/odoo-multiverse/odoomv test 16 lab_selftest   # dernière ligne : OK: 2 tests, 0 failed, 0 error(s)
```

Odoo 16 répond alors sur http://127.0.0.1:8016 (`admin` / `admin`).

En option, ajoutez `odoomv` à votre `PATH` :

```sh
ln -s ~/odoo-multiverse/odoomv ~/.local/bin/odoomv
```

## Commandes

`<v>` vaut 16, 17, 18, 19 ou 20. `up`, `down`, `restart` et `src` acceptent plusieurs versions (`odoomv up 16 18 20`).

| Commande | Effet |
|---|---|
| `odoomv up <v>...` | Démarre Postgres et Odoo `<v>` |
| `odoomv down [<v>...]` | Arrête Odoo `<v>`, ou tout le labo sans argument (volumes conservés) |
| `odoomv restart <v>...` | Redémarre Odoo `<v>` s'il tourne |
| `odoomv init <v> [--no-demo]` | Crée la base `odoo<v>` avec `base` installé et les données de démo |
| `odoomv install <v> <mods> [db]` | Installe des modules (séparés par des virgules) |
| `odoomv update <v> <mods> [db]` | Met à jour des modules |
| `odoomv test <v> <module>` | Lance les tests d'un module dans une base jetable |
| `odoomv link <v> <chemin>` | Copie le module d'un autre projet dans `addons/<v>/` |
| `odoomv unlink <v> <module>` | Supprime cette copie (la source n'est pas touchée) |
| `odoomv shell <v> [db]` | Shell Odoo, accepte un script sur l'entrée standard |
| `odoomv psql <v> [db]` | psql sur la base, accepte du SQL sur l'entrée standard |
| `odoomv logs <v> [-f]` | Logs d'Odoo |
| `odoomv src <v>... [--force]` | Copie le code source d'Odoo de l'image dans `src/<v>/odoo` |
| `odoomv trace <v> <args...>` | Trouve où un modèle, un champ ou une méthode est défini (nécessite [agent-skills](https://github.com/unclecatvn/agent-skills)) |
| `odoomv status` | Conteneurs, bases, ports |

Le détail, les garde-fous et les critères d'échec sont dans [`CLAUDE.md`](CLAUDE.md) (en anglais).

## Versions prises en charge

| Version | Image | URL | Démo par défaut (comportement natif d'Odoo) | Remarques |
|---|---|---|---|---|
| 16 | `odoo:16.0` | http://127.0.0.1:8016 | oui | |
| 17 | `odoo:17.0` | http://127.0.0.1:8017 | oui | |
| 18 | `odoo:18.0` | http://127.0.0.1:8018 | oui | |
| 19 | `odoo:19.0` | http://127.0.0.1:8019 | non (odoomv ajoute `--with-demo`) | |
| 20 | `odoo:20.0` | http://127.0.0.1:8020 | non (odoomv ajoute `--with-demo`) | Les droits d'accès passent par `ir.access` (`security/ir.access.csv`) |

Seules les images Odoo Community sont utilisées.

## Utilisation avec des agents IA

- **Plugin Claude Code** : le dépôt fournit un skill qui apprend à un agent à tester des modules sur le labo depuis n'importe quel projet.

  ```
  /plugin marketplace add rjvdev/odoo-multiverse
  /plugin install odoo-multiverse@odoo-multiverse
  ```

  Le plugin n'installe que le skill. Clonez le labo comme indiqué plus haut, dans `~/odoo-multiverse`.
- **Tout autre agent** : donnez-lui [`CLAUDE.md`](CLAUDE.md). On y trouve les commandes, les bases autorisées, les lignes de verdict et les écarts connus entre versions.
- **Traçage du code** : avec le plugin [agent-skills](https://github.com/unclecatvn/agent-skills), `odoomv trace 19 method res.partner name_get` répond FOUND avec `fichier:ligne`, ou NOT FOUND avec des noms proches, sur le vrai code de cette version.

## FAQ

**Faut-il Claude ou un outil d'IA ?**
Non. `odoomv` est un simple script bash au-dessus de Docker Compose. Le skill, le plugin et `trace` sont facultatifs.

**Odoo Enterprise est-il pris en charge ?**
Non, seulement les images officielles Community. Vous pouvez toutefois lier (`link`) vos propres modules, y compris ceux qui dépendent d'un code que vous fournissez.

**macOS ?**
Oui, avec Docker Desktop.

**Windows ?**
Utilisez WSL2. `odoomv` est un script bash : clonez le dépôt dans le système de fichiers WSL (par exemple `~/odoo-multiverse`, pas `/mnt/c/...`) et lancez-le depuis un shell WSL, avec l'intégration WSL de Docker Desktop activée. Le dépôt impose les fins de ligne LF : une conversion en CRLF ne peut donc pas casser le script.

**Ça marchait hier et ça échoue aujourd'hui. Pourquoi ?**
Les tags `odoo:<v>.0` sont reconstruits en amont, souvent chaque nuit : l'image derrière un tag peut changer d'un jour à l'autre. `docker image inspect odoo:16.0 --format '{{index .RepoDigests 0}}'` affiche le digest utilisé. Pour figer une version, épinglez-la dans `compose.yml` (`image: odoo:16.0@sha256:...`).

**Quel espace disque faut-il ?**
Chaque image Odoo occupe de 2,6 Go (16) à 3,5 Go (20), plus 0,6 Go pour Postgres. Copier le code source avec `odoomv src` ajoute de 1,2 à 1,6 Go par version. Seules les versions que vous démarrez comptent.

**Un port est déjà utilisé.**
Chaque version utilise `127.0.0.1:80<v>` (de 8016 à 8020). Arrêtez ce qui écoute sur ce port, ou changez le port dans `compose.yml`.

**Pourquoi charger les données de démo par défaut ?**
La plupart des tests, y compris ceux d'Odoo, en dépendent. Utilisez `odoomv init <v> --no-demo` pour une base vide. `odoomv test` charge toujours la démo.

**Les identifiants par défaut sont-ils un risque ?**
`admin` / `admin` et `odoo` / `odoo` sont prévus pour un labo local jetable. Les ports ne sont liés qu'à `127.0.0.1`. Ne les exposez pas sur un réseau et n'y chargez pas de vraies données client.

## Contribuer

Les contributions sont les bienvenues. Voir [CONTRIBUTING.md](CONTRIBUTING.md) et le [code de conduite](CODE_OF_CONDUCT.md). Pour signaler une vulnérabilité, voir [SECURITY.md](SECURITY.md).

## Licence

[MIT](LICENSE)

---

**Projet non affilié à Odoo S.A.** Odoo est une marque d'Odoo S.A. Ce projet utilise uniquement les images Docker publiques officielles.
