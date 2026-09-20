all:
	mkdir -p /home/mlakhal/data/mariadb
	mkdir -p /home/mlakhal/data/wordpress
	docker compose -f ./srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down


clean:
	docker compose -f srcs/docker-compose.yml down -v

fclean: clean
	docker system prune -af
	rm -rf /home/mlakhal/data/*
re: fclean all