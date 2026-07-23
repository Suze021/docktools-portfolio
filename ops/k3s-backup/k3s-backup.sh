#!/usr/bin/env bash
set -Eeuo pipefail

backup_dir=/var/backups/k3s
retention_days=14
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
archive="$backup_dir/k3s-$timestamp.tar.gz"
temporary="$archive.partial"
k3s_was_active=0

install -d -m 0700 "$backup_dir"

restart_k3s() {
  if (( k3s_was_active )); then
    systemctl start k3s
  fi
  rm -f -- "$temporary"
}
trap restart_k3s EXIT

if systemctl is-active --quiet k3s; then
  k3s_was_active=1
  systemctl stop k3s
fi

paths=(var/lib/rancher/k3s/server etc/rancher/k3s)
if [[ -d /var/lib/rancher/k3s/storage ]]; then
  paths+=(var/lib/rancher/k3s/storage)
fi

tar --numeric-owner --xattrs --acls -C / -czf "$temporary" "${paths[@]}"
chmod 0600 "$temporary"
mv -- "$temporary" "$archive"

if (( k3s_was_active )); then
  systemctl start k3s
  k3s_was_active=0
fi

find "$backup_dir" -maxdepth 1 -type f \
  \( -name 'k3s-*.tar.gz' -o -name 'k3s-*.tar.gz.sha256' \) \
  -mtime "+$retention_days" -delete
sha256sum "$archive" >"$archive.sha256"

trap - EXIT
printf 'Backup concluido: %s\n' "$archive"
