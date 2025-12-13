# clear view of JWT payload

ACCESS=$(curl -s \
  -d "client_id=kubernetes" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "grant_type=password" \
  http://localhost:8081/realms/stack4things/protocol/openid-connect/token \
  | jq -r .access_token)

ACCESS="$ACCESS" python3 - <<'PY'
import os, json, base64
t=os.environ["ACCESS"]
payload=t.split('.')[1]
payload += '=' * (-len(payload) % 4)
payload = payload.replace('-','+').replace('_','/')
print(json.dumps(json.loads(base64.b64decode(payload)), indent=2))
PY
