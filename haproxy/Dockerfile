# Pull base image
FROM ubuntu:xenial
MAINTAINER Fedor Patrakov <freddy-good@yandex.ru>

# Environment variables
ENV DEBIAN_FRONTEND noninteractive

# Install Dig.
#RUN \
#  apt-get update && \
#  apt-get install -y rsyslog

# Install Haproxy.
RUN \
  apt-get update && \
  apt-get install -y haproxy && \
  sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy && \
  rm -rf /var/lib/apt/lists/*

# Define mountable directories.
VOLUME ["/var/log", "/etc/haproxy"]

# Define working directory.
WORKDIR /etc/haproxy

# Define default command.
CMD ["haproxy", "-f", "haproxy.cfg", "-p", "/var/run/haproxy.pid"]

# Expose ports.
EXPOSE 80
