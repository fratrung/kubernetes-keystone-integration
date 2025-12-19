#!/bin/bash
set -e

MARKER_FILE=/etc/keystone/.bootstrapped

echo ">>> Keystone entrypoint avviato"

if [ ! -f "$MARKER_FILE" ]; then
  echo ">>> Primo avvio: Fase 2 (bootstrap Keystone)"

  echo ">>> keystone-manage db_sync"
  keystone-manage db_sync

  echo ">>> keystone-manage fernet_setup"
  keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

  echo ">>> keystone-manage credential_setup"
  keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

  echo ">>> keystone-manage bootstrap"
  keystone-manage bootstrap --bootstrap-password admin \
    --bootstrap-admin-url http://localhost:5000/v3/ \
    --bootstrap-internal-url http://localhost:5000/v3/ \
    --bootstrap-public-url http://localhost:5000/v3/ \
    --bootstrap-region-id RegionOne

  echo ">>> chown -R keystone:keystone /etc/keystone"
  chown -R keystone:keystone /etc/keystone

  echo ">>> Fase 2 completata"

  echo ">>> Avvio Apache per Fase 3 (CLI federazione)"
  apache2ctl -DFOREGROUND &
  APACHE_PID=$!

  echo ">>> Attendo che Keystone risponda su http://localhost:5000/v3/..."
  until curl -sf http://localhost:5000/v3/ >/dev/null 2>&1; do
    echo "   ...ancora non pronto, riprovo tra 3s"
    sleep 3
  done
  echo ">>> Keystone è UP"

  echo ">>> Esporto variabili OS_* (come da guida)"
  export OS_USERNAME=admin
  export OS_PASSWORD=admin
  export OS_PROJECT_NAME=admin
  export OS_USER_DOMAIN_NAME=Default
  export OS_PROJECT_DOMAIN_NAME=Default
  export OS_AUTH_URL=http://localhost:5000/v3
  export OS_IDENTITY_API_VERSION=3
  export OS_AUTH_TYPE=password
  export OS_REGION_NAME=RegionOne

  echo ">>> Fase 3: configurazione federazione"

  echo ">>> openstack group create federated_users"
  openstack group create federated_users || true

  echo ">>> openstack role add --group federated_users --project admin admin"
  openstack role add --group federated_users --project admin admin || true

  echo ">>> openstack domain create federated_domain"
  openstack domain create federated_domain || true

  echo ">>> openstack identity provider create keycloak --remote-id https://k3d.host.internal:8443/realms/stack4things"
  openstack identity provider create keycloak \
    --remote-id https://k3d.host.internal:8443/realms/stack4things || true

  echo ">>> openstack mapping create keycloak_mapping --rules /etc/keystone/keystone-mapping.json"
  openstack mapping create keycloak_mapping \
    --rules /etc/keystone/keystone-mapping.json || true

  echo ">>> openstack federation protocol create mapped --identity-provider keycloak --mapping keycloak_mapping"
  openstack federation protocol create mapped \
    --identity-provider keycloak \
    --mapping keycloak_mapping || true

  echo ">>> Fase 3 completata"

  touch "$MARKER_FILE"
  echo ">>> Marker creato: $MARKER_FILE"

  echo ">>> Lascio Apache in esecuzione (wait PID=$APACHE_PID)"
  # QUI NON LO UCCIDIAMO: restiamo attaccati al processo Apache
  echo ">>> Keystone Service Ready"
  wait $APACHE_PID
else
  echo ">>> Keystone già inizializzato, avvio Apache direttamente"
  exec apache2ctl -DFOREGROUND
fi
