#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_USER="${SUDO_USER:-$USER}"

info() { echo "[INFO] $*"; }
ok()   { echo "[ OK ] $*"; }
fail() { echo "[ERRO] $*" >&2; exit 1; }

check_prerequisites() {
  local cmd

  info "Verificando pré-requisitos..."

  for cmd in docker msmtp systemctl curl; do
    command -v "$cmd" > /dev/null || fail "Comando não encontrado: $cmd"
  done

  docker compose version > /dev/null 2>&1 || fail "Docker Compose não encontrado"
  docker info > /dev/null 2>&1 || fail "O Docker não está respondendo. O serviço está rodando?"

  ok "Pré-requisitos encontrados"
}

main() {
  info "Instalando o linux-monitoring-stack em $PROJECT_DIR (usuário: $RUN_USER)"
  check_prerequisites
}

main "$@"
