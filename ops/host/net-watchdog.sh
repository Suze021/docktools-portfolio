#!/usr/bin/env bash
# Vigia da placa de rede do servidor de casa (Realtek RTL8106e, driver r8169).
# Em 08/10/2026 ela parou de passar pacotes com o link de pe e sem nenhum
# erro no kernel; so o reboot devolveu a rede. Roda a cada minuto (timer) e
# escala enquanto o gateway nao responder:
#   3 falhas -> religa a interface | 6 -> recarrega o driver | 10 -> reboot
# Ao voltar, registra qual etapa resolveu: link religado = problema de link,
# driver recarregado = placa travada. Leia com: journalctl -t net-watchdog
set -u
IFACE=${IFACE:-enp2s0}
GW=${GW:-192.168.18.1}
DRY_RUN=${DRY_RUN:-0}
STATE=${STATE:-/run/net-watchdog}
# Reboot no maximo 1 vez a cada 6 h e nunca nos primeiros 30 min de boot,
# para queda do roteador ou de energia nao virar loop de reboot.
REBOOT_STAMP=/var/lib/net-watchdog.last-reboot

mkdir -p "$STATE"
fails=$(cat "$STATE/fails" 2>/dev/null || echo 0)
stage=$(cat "$STATE/stage" 2>/dev/null || echo nenhuma)
log() { logger -t net-watchdog "$*"; echo "$*"; }
act() { if [ "$DRY_RUN" = 1 ]; then log "DRY_RUN: $*"; else "$@"; fi; }

if ping -c 2 -W 2 -I "$IFACE" "$GW" >/dev/null 2>&1; then
  [ "$fails" -gt 0 ] && log "rede voltou apos $fails falha(s); ultima etapa aplicada: $stage"
  echo 0 >"$STATE/fails"; echo nenhuma >"$STATE/stage"
  exit 0
fi

fails=$((fails + 1)); echo "$fails" >"$STATE/fails"
log "gateway $GW sem resposta via $IFACE (falha $fails); neigh: $(ip neigh show "$GW" dev "$IFACE" 2>&1)"

case "$fails" in
  3)
    log "etapa 1: religando $IFACE"; echo religar-interface >"$STATE/stage"
    act ip link set "$IFACE" down; sleep 3; act ip link set "$IFACE" up ;;
  6)
    log "etapa 2: recarregando o driver r8169"; echo recarregar-driver >"$STATE/stage"
    act modprobe -r r8169; sleep 2; act modprobe r8169 ;;
  10)
    up=$(cut -d. -f1 /proc/uptime)
    last=$(cat "$REBOOT_STAMP" 2>/dev/null || echo 0)
    now=$(date +%s)
    if [ "$up" -lt 1800 ] || [ $((now - last)) -lt 21600 ]; then
      log "etapa 3: reboot suprimido (uptime ${up}s, ultimo reboot do vigia ha $((now - last))s)"
    else
      log "etapa 3: reiniciando o servidor"; echo reboot >"$STATE/stage"
      [ "$DRY_RUN" = 1 ] || echo "$now" >"$REBOOT_STAMP"
      act systemctl reboot
    fi ;;
esac
