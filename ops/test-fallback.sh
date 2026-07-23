#!/usr/bin/env bash
set -euo pipefail

namespace="docktools"
deployment="docktools-portfolio"

restore_portfolio() {
  sudo -n k3s kubectl -n "$namespace" scale deployment/$deployment --replicas=1 >/dev/null
  sudo -n k3s kubectl -n "$namespace" rollout status deployment/$deployment --timeout=120s >/dev/null
}

trap restore_portfolio EXIT

sudo -n k3s kubectl -n "$namespace" scale deployment/$deployment --replicas=0 >/dev/null
sudo -n k3s kubectl -n "$namespace" wait --for=delete pod -l app=docktools-portfolio --timeout=60s >/dev/null || true
sleep 3

echo "[FALLBACK_RESPONSE]"
fallback_status=$(curl -sS -D /tmp/docktools-fallback-headers.txt -o /tmp/docktools-fallback-body.html -w '%{http_code}' https://docktools.dev/)
test "$fallback_status" = "200"
grep -qi '^X-DockTools-Fallback: active' /tmp/docktools-fallback-headers.txt
grep -Eio '<title>[^<]+' /tmp/docktools-fallback-body.html | head -n 1

echo "[HEALTH_WHILE_DOWN]"
health_status=$(curl -sS -o /tmp/docktools-fallback-health.txt -w '%{http_code}' https://docktools.dev/healthz || true)
test "$health_status" = "503"
echo "$health_status"

restore_portfolio
trap - EXIT

echo "[RESTORED_RESPONSE]"
for attempt in {1..12}; do
  restored_status=$(curl -sS -D /tmp/docktools-restored-headers.txt -o /tmp/docktools-restored-body.html -w '%{http_code}' https://docktools.dev/)
  if test "$restored_status" = "200" && ! grep -qi '^X-DockTools-Fallback:' /tmp/docktools-restored-headers.txt; then
    break
  fi
  sleep 2
done
test "$restored_status" = "200"
if grep -qi '^X-DockTools-Fallback:' /tmp/docktools-restored-headers.txt; then
  echo "fallback header still present after recovery window" >&2
  exit 1
fi
grep -Eio '<title>[^<]+' /tmp/docktools-restored-body.html | head -n 1

echo "[RESTORED_HEALTH]"
curl --fail --silent --show-error https://docktools.dev/healthz
