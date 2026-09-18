FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

COPY index.html /var/www/html/index.html
COPY style.css /var/www/html/style.css

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]