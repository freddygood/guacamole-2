# Pull base image
FROM ubuntu:xenial
MAINTAINER Fedor Patrakov <freddy-good@yandex.ru>

# Environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV TRY_TOTAL 60
ENV BACKEND=nginx

# Install Dig.
RUN \
  apt-get update && \
  apt-get install -y dnsutils && \
  apt-get install -y rsyslog

# Install Haproxy.
RUN \
  apt-get update && \
  apt-get install -y haproxy && \
  sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy && \
  rm -rf /var/lib/apt/lists/*
ADD haproxy.cfg /etc/haproxy/haproxy.cfg
ADD start.sh /etc/haproxy/start.sh

# Define mountable directories.
VOLUME ["/etc/haproxy"]

# Define working directory.
WORKDIR /etc/haproxy

# Define default command.
CMD ["bash", "/etc/haproxy/start.sh"]

# Expose ports.
EXPOSE 80
