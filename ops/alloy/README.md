# Grafana Alloy

O Alloy `v1.18.0` substitui o Promtail EOL. A configuracao foi gerada pelo
conversor oficial a partir do Promtail ativo e preserva os labels `filename`,
`host` e `job`, o destino Loki e o arquivo legado de posicoes.

O volume `promtail_positions` e montado em `/tmp` durante a transicao para o
Alloy importar os offsets existentes. O estado novo fica em `alloy_data`.
