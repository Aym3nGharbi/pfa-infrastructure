#!/usr/bin/env bash
set -euo pipefail

RUNNER_URL="${RUNNER_URL:-https://github.com/Aym3nGharbi/pfa-infrastructure}"
RUNNER_TOKEN="${RUNNER_TOKEN:-}"
RUNNER_NAME="${RUNNER_NAME:-pfa-vm-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,pfa}"
RUNNER_VERSION="${RUNNER_VERSION:-2.326.0}"
RUNNER_ARCHIVE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
RUNNER_DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_ARCHIVE}"
RUNNER_DIR="/opt/actions-runner"
RUNNER_USER="azureuser"

if [[ -z "${RUNNER_TOKEN}" ]]; then
  echo "RUNNER_TOKEN is required."
  exit 1
fi

sudo mkdir -p "${RUNNER_DIR}"
sudo chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"

cd "${RUNNER_DIR}"

if [[ ! -f "./config.sh" ]]; then
  sudo -u "${RUNNER_USER}" curl -fsSL -o "${RUNNER_ARCHIVE}" "${RUNNER_DOWNLOAD_URL}"
  sudo -u "${RUNNER_USER}" tar xzf "${RUNNER_ARCHIVE}"
  sudo -u "${RUNNER_USER}" ./bin/installdependencies.sh
fi

if [[ -f ".runner" ]]; then
  echo "Runner is already configured."
else
  sudo -u "${RUNNER_USER}" ./config.sh \
    --unattended \
    --url "${RUNNER_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --work "_work" \
    --replace
fi

sudo ./svc.sh install "${RUNNER_USER}"
sudo ./svc.sh start
sudo ./svc.sh status