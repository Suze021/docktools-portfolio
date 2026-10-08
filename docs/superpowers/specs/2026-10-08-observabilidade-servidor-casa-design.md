# Observabilidade do servidor de casa — design

Data: 2026-10-08 · Aprovado em conversa com o usuário.

## Objetivo

Abrir `logs.docktools.dev` de qualquer lugar e entender uma emergência em segundos, e ser avisado
no Telegram sem precisar olhar. Escopo: **só o notebook Samsung** (`suze@192.168.18.33`) e o que
roda nele. Outras máquinas ficam fora.

## Estado de partida

Stack `docktools-proxy` (Caddy, Grafana 13, Loki 2.9, Alloy 1.18, Portainer) em
`/home/suze/stacks/docktools-proxy`. O Alloy lê `/var/lib/docker/containers/*/*.log` sem nome de
container (só `filename`) e com `host="docktools-vps"` herdado da VPS. O Caddy não grava acesso.
Não há métricas, painéis nem alertas. Loki retém 7 dias.

## Componentes

| Componente | Papel | Mudança |
|---|---|---|
| Prometheus (`prom/prometheus`) | guarda métricas, 30 dias | novo, só na rede interna, recebe remote write do Alloy |
| Alloy | coleta tudo | reescrito (abaixo) |
| Loki | guarda logs | retenção 7 → 14 dias |
| Caddy | proxy | log de acesso JSON no stdout + endpoint `metrics` interno por host |
| Grafana | painéis e alertas | datasource Prometheus, 4 painéis e alertas provisionados por arquivo |

## Coleta (Alloy)

**Logs**
- Containers via socket do Docker (`discovery.docker` + `loki.source.docker`), com rótulos
  `container`, `compose_project`, `compose_service`, `host="casa"`.
- Acesso do Caddy: cada requisição em JSON com `request.headers.Cf-Connecting-Ip` (IP real, pois
  tudo chega pelo Cloudflare Tunnel), `Cf-Ipcountry`, host, método, URI, status, duração e
  user-agent. Rótulos só de baixa cardinalidade (`container`, `site`); IP e caminho ficam no corpo
  e são lidos com `| json` nas consultas.
- journald: cloudflared, runner do GitHub, sshd, docker e kernel (OOM killer).

**Métricas**
- Host (`prometheus.exporter.unix`): CPU, RAM, disco de `/` (SSD) e `/boot` (pendrive), rede,
  temperatura (hwmon/thermal) e bateria/AC (`power_supply`).
- Containers (`prometheus.exporter.cadvisor`): CPU, memória, reinícios, último sinal.
- Caddy: requisições por host e código de status.
- Sondas de fora pra dentro (`prometheus.exporter.blackbox`), a cada minuto, nas URLs públicas:
  `docktools.dev/healthz` (200), `openclaw.docktools.dev` (200), `logs` e `portainer` (401 conta
  como no ar, é o basic auth). `pinseeu-openclaw` entra quando o Pin-SeeU migrar.

## Painéis

1. **Emergência** — uma tela: sondas no ar/fora, containers esperados de pé, CPU/RAM/disco/
   pendrive/temperatura, AC ou bateria, últimas linhas de erro de todos os containers.
2. **Acessos** — requisições/min por site e status, top IPs, top países, top caminhos, 4xx/5xx,
   latência, log ao vivo.
3. **Containers** — CPU, memória e reinícios por container; log com filtro por container.
4. **Pin-SeeU** — eventos `pin_search` (candidatos, encontrados, `not_found`), erros do pin-reader
   e do openclaw. Fica vazio até o Pin-SeeU subir com Gmail.

## Alertas (Grafana → Telegram)

Containers esperados: `docktools-caddy`, `docktools-grafana`, `docktools-loki`, `docktools-alloy`,
`docktools-prometheus`, `portainer`, `docktools-portfolio`, `openclaw`, `ollama`; os do Pin-SeeU
(`pin-seeu-openclaw`, `pin-seeu-pin-reader`) entram na lista quando ele migrar. Casa Sobre Rodas e
Vaultwarden estão desativados e ficam fora.

Contact point Telegram com bot dedicado (token em `grafana.env`, nunca no repositório), chat do
usuário `1337622535`. Toda regra notifica também a resolução.

| Alerta | Condição |
|---|---|
| Site fora | sonda falhando por 2 min |
| Container parado | container esperado sem sinal há 2 min |
| Container em loop | mais de 2 reinícios em 15 min |
| Disco | `/` ou `/boot` acima de 85% |
| Memória | uso acima de 90% por 5 min |
| Temperatura | acima de 90 °C por 5 min |
| Queda de energia | notebook fora da tomada (na bateria) |
| Erros 5xx | mais de 10 respostas 5xx em 5 min |
| Pin-SeeU | qualquer `pin_search` com 0 PINs (é sempre anomalia) |
| Sem dados | métricas do host somem por 5 min (Alloy ou Prometheus caiu) |

## Fora do escopo / limites conhecidos

- Se o notebook cair inteiro, o Grafana cai junto e não alerta. Remédio é um dead man's switch
  externo (healthchecks.io), que depende de conta criada pelo usuário; fica como etapa opcional.
- Outras máquinas (VPS do novogc, gcsolar) não são coletadas.

## Versionamento

Configs em `ops/observability/` deste repositório (Alloy, Prometheus, Loki, provisioning e JSON dos
painéis); o servidor recebe cópia. Painel editado na interface que deva permanecer é exportado de
volta para o repositório.

## Verificação

- Cada fonte provada no Explore do Grafana (consulta retorna dados com os rótulos esperados).
- IP real: uma requisição marcada feita daqui aparece com o IP público desta rede.
- Cada alerta disparado de verdade ao menos uma vez (condição forçada, ex.: parar um container,
  sonda para URL inexistente) e a mensagem conferida no Telegram, junto com a de resolução.
- O usuário valida os painéis visualmente.
