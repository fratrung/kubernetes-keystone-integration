TOKEN=$(curl -s -k \
  -X POST "https://host.k3d.internal:8443/realms/stack4things/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=kubernetes" \
  -d "username=testuser" \
  -d "password=testpassword" | jq -r .access_token)

echo $TOKEN | wc -c

echo "$TOKEN" | cut -d. -f2 | base64 -d | jq

kubectl cluster-info

kubectl get namespaces \
  --server=https://0.0.0.0:43545 \
  --token="$TOKEN" \
  --insecure-skip-tls-verify=true
