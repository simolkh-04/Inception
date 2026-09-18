FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y vsftpd && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/vsftpd/empty

COPY vsftpd.conf /etc/vsftpd.conf
COPY setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

CMD ["/usr/local/bin/setup.sh"]