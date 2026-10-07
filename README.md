# Portfólio — Guilherme de Oliveira Rocha

Portfólio pessoal de Guilherme de Oliveira Rocha, publicado em `https://docktools.dev`.

## Arquitetura

- HTML, CSS e JavaScript sem dependências de runtime.
- Nginx não-root em Docker Compose no servidor de casa (`ops/portfolio-compose.yaml`).
- Cloudflare Tunnel termina o TLS; o Caddy encaminha o domínio ao container pela rede `edge`.
- GitHub Actions em runner próprio do servidor publica cada push para `main`.
- Health check no container e externo; `nginx -t` antes de recarregar a configuração.

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
docker compose -f /home/suze/stacks/portfolio/compose.yaml ps
curl -fsS https://docktools.dev/healthz
```

O bloco do proxy está em `ops/Caddyfile.docktools`.

## Infraestrutura adjacente

- `ops/k3s/csr-staging`: manifests do app Casa Sobre Rodas em staging; o banco continua no Docker.
- `ops/k3s-backup`: backup consistente diário do datastore e dos volumes locais do K3s.
- `ops/alloy`: substituição do Promtail EOL pelo Grafana Alloy, preservando labels e posições do Loki.
