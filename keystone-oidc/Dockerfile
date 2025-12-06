FROM lucadagati/iotronic-keystone

# Passiamo a root per installare i pacchetti
USER root

# Aggiorniamo i repository e installiamo il modulo OIDC per Apache
RUN apt-get update && \
    apt-get install -y libapache2-mod-auth-openidc && \
    rm -rf /var/lib/apt/lists/*

# Abilitiamo il modulo
RUN a2enmod auth_openidc

COPY keystone-config/keystone-entrypoint.sh /usr/local/bin/keystone-entrypoint.sh
RUN chmod +x /usr/local/bin/keystone-entrypoint.sh

