# CSR staging no K3s

O app roda no namespace `csr-staging` e acessa o PostgreSQL mantido no Docker
pelo gateway interno `172.17.0.1:15432`. O banco nao e publicado em interfaces
externas.

O Secret `csr-staging-env` nao fica no Git. Na migracao inicial ele foi criado a
partir do ambiente do container Docker que estava em producao, alterando apenas
o host do `DATABASE_URL` de `db:5432` para `172.17.0.1:15432`.

O Caddy encaminha `casa-dev.docktools.dev` primeiro ao NodePort `30081` e usa o
container Docker anterior como fallback durante a estabilizacao. Para validar:

```bash
kubectl -n csr-staging rollout status deployment/csr-staging-app
curl -fsS http://172.17.0.1:30081/api/health
curl -fsS https://casa-dev.docktools.dev/api/health
```
