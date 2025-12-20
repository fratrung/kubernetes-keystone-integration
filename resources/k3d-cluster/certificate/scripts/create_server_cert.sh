cat > san.cnf <<'EOF'
[req]
prompt = no
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = host.k3d.internal

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = host.k3d.internal
DNS.2 = localhost
IP.1  = 127.0.0.1
EOF

openssl genrsa -out keycloak.key 4096
openssl req -new -key keycloak.key -out keycloak.csr -config san.cnf
openssl x509 -req -in keycloak.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out keycloak.crt -days 365 -sha256 -extensions req_ext -extfile san.cnf
