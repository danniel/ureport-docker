# The build image
FROM debian:bullseye-slim

ENV PYTHONUNBUFFERED=1
ENV IS_CONTAINERIZED=True

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential gettext libpq-dev \
        python3.9 python3.9-dev python3-pip python3-venv \
        nodejs npm

# UReport source
ADD https://github.com/rapidpro/ureport/archive/refs/tags/v1.2.51.tar.gz /tmp
RUN mkdir -p /var/www/ && tar -C /var/www/ -xzf /tmp/ureport-1.2.51.tar.gz \
    && mv /var/www/ureport-1.2.51/ /var/www/ureport/

# Python venv
WORKDIR /var/www/ureport
ENV VIRTUAL_ENV=/opt/venv PATH=/opt/venv/bin:/root/.local/bin:$PATH
RUN python3 -m venv $VIRTUAL_ENV \
    && python3.9 -m pip install poetry gunicorn[gevent] \
    && poetry install

# Less and Coffescript
RUN npm install less -g --no-audit && npm install coffeescript -g --no-audit

# Supervision
ARG S6_OVERLAY_VERSION=3.1.2.1
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME 0

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

ENTRYPOINT ["/init"]

COPY docker/s6-rc.d /etc/s6-overlay/s6-rc.d

# NGINX
COPY docker/nginx/selfsigned* /etc/ssl/localcerts/
COPY docker/nginx/nginx.conf /etc/nginx/sites-available/default

# Application set up
COPY docker/ureport/settings.py ureport/settings.py
RUN npm install -y --no-audit \
    && python3.9 manage.py collectstatic

EXPOSE 80