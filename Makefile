NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down --volumes --remove-orphans

re: fclean all