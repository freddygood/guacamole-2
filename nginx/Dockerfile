# Pull base image
FROM ubuntu:xenial
MAINTAINER Fedor Patrakov <freddy-good@yandex.ru>

# Environment variables
ENV DEBIAN_FRONTEND noninteractive

# Install Nginx.
RUN \
  apt-get update && \
  apt-get install -y curl && \
  echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list && \
  curl -s http://nginx.org/keys/nginx_signing.key -o /tmp/nginx_signing.key && \
  apt-key add /tmp/nginx_signing.key && \
  apt-get update && \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf
RUN mkdir -p /www/static

# Define mountable directories.
VOLUME ["/var/log/nginx", "/etc/nginx/conf.d", "/www/static"]

# Define working directory.
WORKDIR /etc/nginx

# Define default command.
CMD ["nginx"]

# Expose ports.
EXPOSE 80
