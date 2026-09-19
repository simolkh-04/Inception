# Developer Documentation

This document describes how a developer can set up, build, run, and maintain the Inception project.

## 1. Setting up the environment from scratch

### Prerequisites

- A Linux virtual machine (Debian or Alpine-based host recommended, matching the base image used for the containers).
- `docker` and the `docker compose` plugin installed.
- `make`.
- `git`.

### Repository layout

```
.
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/{Dockerfile, .dockerignore, conf/, tools/}
        ├── nginx/{Dockerfile, .dockerignore, conf/, tools/}
        ├── wordpress/{Dockerfile, .dockerignore, conf/, tools/}
        └── bonus/...
```

### Configuration files and secrets

1. **`srcs/.env`** — holds non-sensitive configuration used by `docker-compose.yml` (domain name, database name, database user, WordPress URLs, etc.). Copy/adjust the provided template if one exists, or create it following the variable names referenced in `docker-compose.yml`.

2. **`secrets/`** — holds sensitive values only, one value per file, no trailing formatting beyond the raw secret:
   - `db_password.txt` — password for the non-root MySQL/MariaDB user used by WordPress.
   - `db_root_password.txt` — MariaDB root password.
   - `credentials.txt` — WordPress admin and secondary user credentials (used by the WordPress container's setup script to create both accounts at first boot).

   These files are referenced in `docker-compose.yml` under the top-level `secrets:` key and mounted read-only inside containers at `/run/secrets/<name>`. **Never** commit real values — make sure `secrets/` is listed in `.gitignore`.

3. **Domain name** — `<login>.42.fr` must resolve to the VM's local IP address. On the host (or inside the VM depending on your setup), add a line to `/etc/hosts`:

   ```
   127.0.0.1   <login>.42.fr
   ```

   (Replace `127.0.0.1` with the VM's actual IP if accessing it from outside the VM itself.)

## 2. Building and launching the project

The `Makefile` at the root wraps the `docker compose` commands:

| Target | Effect |
|---|---|
| `make` / `make all` | Builds all images from their Dockerfiles and starts the containers in detached mode (`docker compose -f srcs/docker-compose.yml up -d --build`). |
| `make down` | Stops and removes the containers, keeping images, volumes and networks intact. |
| `make clean` | `down` + removes the built images and the docker network. |
| `make fclean` | `clean` + removes the named volumes and the corresponding data under `/home/<login>/data`. |
| `make re` | `fclean` + `make all`, i.e. a full rebuild from a clean state. |

Under the hood, each service is built from its own Dockerfile:

```sh
docker compose -f srcs/docker-compose.yml build          # build images only
docker compose -f srcs/docker-compose.yml up -d           # start containers
docker compose -f srcs/docker-compose.yml logs -f <name>  # tail logs of one service
```

Each Dockerfile is based on the same pinned, non-`latest` version of Alpine or Debian across all services, and each container's main process runs in the foreground as PID 1 (no `tail -f`, `sleep infinity`, or similar hacky patches), so Docker's restart policy and signal handling work correctly.

## 3. Managing containers and volumes

Useful day-to-day commands:

```sh
docker ps -a                          # list all containers and their state
docker compose -f srcs/docker-compose.yml restart <name>   # restart one service
docker exec -it <container_name> sh   # get a shell inside a running container
docker volume ls                      # list Docker volumes
docker volume inspect <volume_name>   # inspect a volume, including its Mountpoint
docker network ls                     # list Docker networks
docker network inspect <network_name> # inspect the project's network and connected containers
```

To rebuild a single service after editing its Dockerfile or configuration:

```sh
docker compose -f srcs/docker-compose.yml up -d --build <service_name>
```

## 4. Where project data is stored and how it persists

Two named volumes are declared in `docker-compose.yml`:

- One for **MariaDB's data directory** (`/var/lib/mysql` inside the container).
- One for **WordPress's website files** (`/var/www/html` inside the container, shared with NGINX for serving static assets).

Both volumes use the `local` driver with a bind-type mount option pointing at the host path, so that Docker manages them as proper **named volumes** while their actual data is written to:

```
/home/<login>/data/
```

on the host machine (with one subdirectory per volume). This satisfies the project's requirement to have the data end up at a predictable host location while keeping the volumes as Docker-managed named volumes rather than plain bind mounts declared directly on services.

Because the data lives in named volumes rather than inside the containers themselves, running `make down` or restarting containers does **not** erase the WordPress site or its database — only `make fclean` (or a manual `docker volume rm`) removes this persisted data.

To back up the data manually, you can archive the contents of `/home/<login>/data/` while the stack is stopped, or use `docker run --rm -v <volume_name>:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data` to snapshot a volume without touching the host path directly.