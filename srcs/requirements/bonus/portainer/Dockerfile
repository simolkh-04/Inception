FROM debian:bookworm

RUN apt update && apt install -y wget ca-certificates tar \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/portainer.tar.gz \
    https://github.com/portainer/portainer/releases/download/2.39.5/portainer-2.39.5-linux-amd64.tar.gz \
    && mkdir -p /opt/portainer \
    && tar -xzf /tmp/portainer.tar.gz -C /opt/portainer --strip-components=1 \
    && chmod +x /opt/portainer/portainer \
    && rm /tmp/portainer.tar.gz

RUN mkdir -p /data

WORKDIR /opt/portainer

EXPOSE 9443

ENTRYPOINT ["./portainer"]