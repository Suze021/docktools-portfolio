#!/usr/bin/env bash
set -euo pipefail

runner_version="2.336.0"
runner_sha256="04cf0be1aff4c3ec3554466c39124ca250e3effd8873bb7e8d68535aa9505d5d"
runner_archive="actions-runner-linux-x64-${runner_version}.tar.gz"
runner_root="/opt/actions-runner/docktools-portfolio"
repository_url="https://github.com/Suze021/docktools-portfolio"

read -r registration_token_base64
registration_token=$(printf '%s' "$registration_token_base64" | tr -d '\r' | base64 --decode)
unset registration_token_base64

sudo -n mkdir -p "$runner_root"
sudo -n chown ubuntu:ubuntu "$runner_root"
cd "$runner_root"

if [[ ! -f .runner ]]; then
  curl --fail --silent --show-error --location \
    "https://github.com/actions/runner/releases/download/v${runner_version}/${runner_archive}" \
    --output "$runner_archive"
  printf '%s  %s\n' "$runner_sha256" "$runner_archive" | sha256sum --check
  tar xzf "$runner_archive"

  ./config.sh \
    --url "$repository_url" \
    --token "$registration_token" \
    --name "vps-docktools-portfolio" \
    --labels "docktools-portfolio" \
    --work "_work" \
    --unattended \
    --replace
fi

unset registration_token

if [[ ! -f /etc/systemd/system/actions.runner.Suze021-docktools-portfolio.vps-docktools-portfolio.service ]]; then
  sudo -n ./svc.sh install ubuntu
fi
sudo -n ./svc.sh start
sudo -n ./svc.sh status
