#!/bin/bash
set -e

echo "[INFO] Keystone DB sync..."
mkdir -p /var/lib/keystone
keystone-manage fernet_setup --keystone-user www-data --keystone-group www-data || true
keystone-manage credential_setup --keystone-user www-data --keystone-group www-data || true
keystone-manage db_sync

echo "[INFO] Keystone bootstrap..."
keystone-manage bootstrap \
  --bootstrap-username admin \
  --bootstrap-password s4t \
  --bootstrap-admin-url http://keystone:5000/v3 \
  --bootstrap-public-url http://keystone:5000/v3 \
  --bootstrap-region-id RegionOne || true

export OS_USERNAME=admin
export OS_PASSWORD=s4t
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://keystone:5000/v3
export OS_IDENTITY_API_VERSION=3

echo "[INFO] Wait for Keystone API to be up (Apache)..."

# Config base Apache vhost (super minimale, porta 5000)
cat >/etc/apache2/sites-available/keystone.conf <<EOF
Listen 5000
<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public user=www-data group=www-data processes=5 threads=1
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    ErrorLog /var/log/apache2/keystone_error.log
    CustomLog /var/log/apache2/keystone_access.log combined
</VirtualHost>
EOF

a2dissite 000-default.conf || true
a2ensite keystone.conf

echo "[INFO] Starting Apache..."
apachectl -D FOREGROUND
