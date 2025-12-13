
# view_response
curl -s \
  -d "client_id=kubernetes" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "grant_type=password" \
  http://localhost:8081/realms/stack4things/protocol/openid-connect/token | jq
