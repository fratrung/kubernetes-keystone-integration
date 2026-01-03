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

  # Domain dove vivono identità/gruppi federati (pulito)
  openstack domain create federated_domain || true

  # Gruppo "catch-all" per chi entra via federazione (permessi minimi)
  openstack group create --domain federated_domain federated_users || true

  # Progetto "holding" senza privilegi reali
  #openstack project create federated_access --domain federated_domain || true
  # usa reader se esiste, altrimenti member
  #openstack role add --group federated_users --group-domain federated_domain \
  #  --project federated_access --project-domain federated_domain reader || true

  # Gruppo provider/platform admin (questi fanno provisioning)
  openstack group create --domain federated_domain s4t:platform-admins || true
  openstack role add --group s4t:platform-admins --group-domain federated_domain \
    --domain Default admin || true

  # Gruppo "project creator" (flag/logico: lo userai lato S4T/Kubernetes, NON qui)
  openstack group create --domain federated_domain s4t:project-creator || true

   # Progetto IoT lab nel dominio Default (quello standard dei progetti)
  openstack project create testuser-iot-lab --domain Default || true

  echo '[INFO] Creazione dei servizi di Iotronic...'

  openstack project create service \
    --domain Default \
    --description "Service Project" || true

  openstack service create iot \
    --name Iotronic || true

  echo '[INFO] Iotronic User Create...'
  openstack user create iotronic \
    --password unime || true

  echo '[INFO] Iotronic roles...'
  openstack role create admin_iot_project || true
  openstack role create manager_iot_project || true
  openstack role create user_iot || true

  openstack role add --project service --user iotronic admin || true
  openstack role add --project service --user iotronic admin_iot_project || true
  openstack role add --project admin --user admin admin_iot_project || true

  openstack user create s4t-platform \
  --password platform-secret \
  --domain Default || true

  # Gruppi specifici iot-lab nel dominio federated_domain
  openstack group create --domain federated_domain 's4t:testuser-iot-lab:admin_iot_project'  || true
  openstack group create --domain federated_domain 's4t:testuser-iot-lab:manager_iot_project' || true
  openstack group create --domain federated_domain 's4t:testuser-iot-lab:user_iot'   || true

  openstack role add \
  --user s4t-platform \
  --user-domain Default \
  --domain Default \
  admin || true

  # Assegna ruoli ai gruppi sul progetto iot-lab
  # Admin del progetto
  openstack role add \
    --group 's4t:testuser-iot-lab:admin_iot_project' \
    --group-domain federated_domain \
    --project testuser-iot-lab \
    --project-domain Default \
    admin_iot_project || true

    # Manager (dev/power user)
  openstack role add \
    --group 's4t:testuser-iot-lab:manager_iot_project' \
    --group-domain federated_domain \
    --project testuser-iot-lab \
    --project-domain Default \
    manager_iot_project || true

  # User (solo utilizzo servizi / reader)
  openstack role add \
    --group 's4t:testuser-iot-lab:user_iot' \
    --group-domain federated_domain \
    --project testuser-iot-lab \
    --project-domain Default \
    user_iot || true

  # IdP + mapping + protocol
  openstack identity provider create keycloak \
    --remote-id https://host.k3d.internal:8443/realms/stack4things || true

  openstack mapping create keycloak_mapping \
    --rules /etc/keystone/keystone-mapping.json || true

  openstack federation protocol create mapped \
    --identity-provider keycloak \
    --mapping keycloak_mapping || true


  echo ">>> Fase 3 completata"

  touch "$MARKER_FILE"
  echo ">>> Marker creato: $MARKER_FILE"

  echo ">>> Lascio Apache in esecuzione (wait PID=$APACHE_PID)"
  echo ">>> Keystone Service Ready"
  wait $APACHE_PID
else
  echo ">>> Keystone già inizializzato, avvio Apache direttamente"
  exec apache2ctl -DFOREGROUND
fi
