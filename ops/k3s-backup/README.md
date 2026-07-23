# Backup do K3s

O timer executa diariamente por volta de `05:15 UTC` (`02:15` em Brasilia),
mantem 14 dias e grava os arquivos em `/var/backups/k3s` com permissao `0600`.

Como o cluster atual usa SQLite, o servico para o K3s durante a copia para obter
um snapshot consistente e o inicia novamente mesmo se a copia falhar. Nesse
intervalo, o Caddy entrega a landing de contingencia.

O backup inclui o datastore, token, certificados e configuracao do servidor,
alem dos volumes `local-path` quando existirem. Ele protege contra erro
operacional, mas continua no disco da VPS; uma copia externa ainda e necessaria
para proteger contra perda integral da instancia.
