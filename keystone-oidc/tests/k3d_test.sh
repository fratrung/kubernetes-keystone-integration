kubectl config set-credentials oidc \
  --exec-command=kubelogin \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://host.k3d.internal:8443/realms/stack4things \
  --exec-arg=--oidc-client-id=kubernetes \
  --exec-arg=--oidc-extra-scope=email \
  --exec-arg=--oidc-extra-scope=profile \
  --exec-arg=--listen-address=127.0.0.1:8000

  
kubectl config set-context --current --user=oidc
