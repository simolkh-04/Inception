# User Documentation

This document explains, in simple terms, how to use the Inception stack as an end user or administrator, without needing to know how it was built.

## 1. What services does the stack provide?

The stack is made of three core services working together:

| Service | Role |
|---|---|
| **NGINX** | The only entry point of the infrastructure. It serves the website securely over HTTPS (TLSv1.2/TLSv1.3) on port 443. |
| **WordPress + php-fpm** | The website itself: a WordPress installation that generates the pages you see, plus a small administration panel to manage content. |
| **MariaDB** | The database that stores all the website's content (pages, posts, users, settings). It is not directly accessible from outside. |

Two persistent storage areas (Docker volumes) keep your data safe even if containers are restarted:
- The **database** volume (all WordPress content and settings).
- The **website files** volume (WordPress core files, themes, plugins, uploads).

## 2. Starting and stopping the project

From the root of the repository, on the virtual machine:

```sh
make          # build the images (if needed) and start all services
```

To stop the services without deleting any data:

```sh
make down
```

To stop the services and free up all resources (containers, images, networks):

```sh
make clean
```

To also remove the persisted data (database and website files) and start completely fresh:

```sh
make fclean
```

To rebuild everything from scratch:

```sh
make re
```

## 3. Accessing the website and the administration panel

Once the stack is running, open a browser and go to:

```
https://<login>.42.fr
```

You may see a browser warning about the certificate, since it is self-signed for local development purposes — this is expected; proceed to the site.

To access the **WordPress administration panel** (to manage pages, posts, plugins, users, etc.), go to:

```
https://<login>.42.fr/wp-admin
```

Log in with one of the two configured WordPress accounts:
- An **administrator** account (full access to the site's settings). Note that, per project requirements, its username does not contain "admin" or "administrator".
- A regular **user** account (limited permissions, e.g. editor/author role).

## 4. Locating and managing credentials

For security reasons, no password is stored in plain text inside the code or the Docker images. Credentials are kept in two places:

- `srcs/.env` — non-sensitive configuration values (domain name, database name, usernames).
- `secrets/` folder at the root of the project — sensitive values only:
  - `db_password.txt` — password of the WordPress database user.
  - `db_root_password.txt` — root password of MariaDB.
  - `credentials.txt` — WordPress account credentials (admin and regular user).

These files are excluded from version control (via `.gitignore`) and must be kept private. If you need to change a password, edit the relevant file in `secrets/` and restart the stack with `make re` so the new value is taken into account.

## 5. Checking that the services are running correctly

To list the running containers and check their status:

```sh
docker ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should appear with a status of `Up` (and `healthy` if a healthcheck is configured). If a container shows `Restarting` or `Exited`, something is wrong.

To view the logs of a specific service (useful to diagnose an issue):

```sh
docker logs nginx
docker logs wordpress
docker logs mariadb
```

To confirm the website itself is reachable, simply open `https://<login>.42.fr` in a browser, or test it from the command line:

```sh
curl -k https://<login>.42.fr
```

(The `-k` flag ignores the self-signed certificate warning for this local test.)

If something doesn't come up correctly, see `DEV_DOC.md` for deeper troubleshooting and maintenance commands.