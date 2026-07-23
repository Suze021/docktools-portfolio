# DockTools Portfolio

Landing page estática do portfólio DockTools, publicada em `https://docktools.dev`.

## Arquitetura

- HTML, CSS e JavaScript sem dependências de runtime.
- Nginx não-root no K3s.
- Caddy existente mantém TLS e encaminha o domínio ao NodePort `30080`.
- Se o K3s ficar indisponível, o Caddy encaminha automaticamente para um Nginx mínimo que serve a landing anterior.
- GitHub Actions em runner próprio da VPS publica cada push para `main`.
- Readiness, liveness, limites de recursos, health check externo e rollback em falha.

## Desenvolvimento local

Sirva a pasta com qualquer servidor HTTP estático. Exemplo:

```powershell
python -m http.server 4173
```

Acesse `http://localhost:4173`.

## Deploy

O deploy é automático após push para `main`. Também pode ser disparado manualmente em **Actions → Deploy production → Run workflow**.

Validação no servidor:

```bash
kubectl -n docktools get deploy,pod,service
curl -fsS https://docktools.dev/healthz
```

O bloco do proxy está em `ops/Caddyfile.docktools`; o servidor de contingência está descrito em `ops/fallback-compose.yaml`.
