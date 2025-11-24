FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------
#  Install base dependencies
# -----------------------------
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-wsgi-py3 \
    python3-pip \
    python3-dev \
    sqlite3 \
    curl \
    vim \
    openssl \
    && apt-get clean

# -----------------------------
#  Install Keystone + client
# -----------------------------
RUN pip install \
    keystone \
    keystoneauth1 \
    python-openstackclient \
    pymysql

# -----------------------------
#  Keystone WSGI setup
# -----------------------------
RUN mkdir -p /var/www/cgi-bin/keystone
RUN keystone-wsgi-public > /var/www/cgi-bin/keystone/main

# Enable apache modules
RUN a2enmod wsgi headers rewrite ssl

# Copy keystone.conf (lo creiamo dopo)
COPY keystone.conf /etc/keystone/keystone.conf

# Create signing key for OIDC
RUN mkdir -p /etc/keystone && \
    openssl genrsa -out /etc/keystone/oidc_signing.key 2048 && \
    chmod 600 /etc/keystone/oidc_signing.key

# Copy bootstrap script
COPY bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

EXPOSE 5000

CMD ["/bootstrap.sh"]
