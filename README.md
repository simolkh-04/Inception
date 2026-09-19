*This project has been created as part of the 42 curriculum by mlakhal.*

# Inception

## Description

**Inception** is a system administration project whose goal is to set up a small, secure infrastructure made of several Docker services, orchestrated with `docker compose`, and running on a dedicated virtual machine.

The infrastructure is composed of three mandatory containers, each built from a custom Dockerfile (no ready-made images pulled from Docker Hub, except the base Alpine/Debian image):

- **NGINX** — configured with TLSv1.2/TLSv1.3 only, acting as the single entry point of the infrastructure (port 443).
- **WordPress + php-fpm** — the WordPress application, installed and configured, running without its own web server (nginx handles TLS termination and proxies PHP requests via php-fpm on port 9000).
- **MariaDB** — the database used by WordPress, running without nginx.

Two Docker **named volumes** persist data:

- One for the WordPress database (`MariaDB` data directory).
- One for the WordPress website files.

Both volumes are configured so their data physically lives under `/home/<login>/data` on the host, while still being managed as Docker named volumes (not bind mounts).

All containers communicate through a dedicated **docker network**, and all are configured to automatically **restart** in case of a crash.

The domain `<login>.42.fr` is configured to resolve to the host's local IP address, so the WordPress site is reachable at `https://<login>.42.fr`.

### Project structure

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
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        └── bonus/
            └── ...
```

### Design choices and comparisons

**Virtual Machines vs Docker**
A VM virtualizes an entire machine (kernel, hardware drivers, full OS), which is heavier, slower to boot, and consumes more resources. Docker containers share the host's kernel and only isolate the process/filesystem/network space, making them lightweight, fast to start, and easy to reproduce. Inception uses one VM as the host, and Docker inside it to isolate each service, combining VM-level isolation from the outside world with container-level modularity for the services themselves.

**Secrets vs Environment Variables**
Environment variables (`.env`) are convenient for non-sensitive configuration (domain name, usernames, database names) but are visible in `docker inspect`, process listings, and easily leaked into logs or version control. Docker **secrets** are mounted as files inside the container at runtime (under `/run/secrets/`), are not persisted in the image layers, and are not exposed through `docker inspect`. In this project, actual passwords (MySQL root password, MySQL user password, WordPress admin credentials) are stored as secrets, while non-sensitive configuration values are stored as environment variables.

**Docker Network vs Host Network**
`network: host` makes the container share the host's network stack directly, removing network isolation and making port management fragile (no internal DNS between services, port conflicts on the host). A custom **docker-network** (bridge) gives each container its own network namespace, provides automatic DNS resolution by service name (e.g., `mariadb`, `wordpress`), and only explicitly exposes the ports that need to be reachable from outside (443 on nginx). This project therefore uses a dedicated bridge network and forbids `network: host`, `--link`, and `links:`.

**Docker Volumes vs Bind Mounts**
Bind mounts map an arbitrary host path directly into the container and are managed outside of Docker's lifecycle, which makes permissions, portability, and backup handling less predictable. Docker **named volumes** are managed by Docker itself, have a defined lifecycle tied to `docker volume` commands, and are more portable across environments. This project configures the named volumes' driver options so their data is physically stored under `/home/<login>/data`, satisfying the subject's requirement while keeping the volumes as proper Docker named volumes rather than bind mounts.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker and Docker Compose installed.
- `make`.

### Setup

1. Clone the repository.
2. Fill in the secret files under `secrets/` (`db_password.txt`, `db_root_password.txt`, `credentials.txt`) with your own values. These files are git-ignored and must never be committed.
3. Adjust `srcs/.env` if needed (domain name, non-sensitive configuration).
4. Add an entry to your local machine's hosts resolution (or configure your VM's `/etc/hosts`) so that `<login>.42.fr` points to your local IP address.

### Build and run

```sh
make          # builds the images and starts the containers
make down     # stops and removes the containers
make clean    # removes containers, images and networks
make fclean   # clean + removes volumes and local data
make re       # fclean + make
```

### Access

Once running, the website is available at:

```
https://<login>.42.fr
```

See `USER_DOC.md` for details on accessing the site and the admin panel, and `DEV_DOC.md` for developer-oriented setup and maintenance instructions.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Official WordPress documentation](https://wordpress.org/documentation/)
- [WP-CLI documentation](https://wp-cli.org/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [Docker secrets documentation](https://docs.docker.com/engine/swarm/secrets/)
- 42 Inception subject (this document)

### AI usage

AI (Claude) was used during this project as a support tool, in line with the AI usage guidelines described in the subject:

- To clarify how specific Docker/Compose features work (e.g., named volumes with custom mount points, healthchecks, `depends_on` conditions) before writing the actual configuration by hand.
- To help draft and structure this `README.md`/`USER_DOC.md`/`DEV_DOC.md` documentation, which was then reviewed, corrected, and completed manually to match the actual implementation.
- To review Dockerfiles and configuration files for obvious mistakes (e.g., use of forbidden patterns like `tail -f` or hardcoded passwords) — all generated suggestions were tested and understood before being kept.

No AI-generated code was used without being fully understood, tested, and reviewed, in accordance with the project's learner rules.