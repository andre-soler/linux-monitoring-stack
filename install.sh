#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_USER="${SUDO_USER:-$USER}"

info() { echo "[INFO] $*"; }
ok()   { echo "[ OK ] $*"; }
warn() { echo "[AVISO] $*" >&2; }
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

prepare_env() {
  local env_file="$PROJECT_DIR/.env"

  info "Verificando o arquivo .env..."

  if [[ ! -f "$env_file" ]]; then
    cp "$PROJECT_DIR/.env.example" "$env_file"
    chmod 600 "$env_file"
    fail "Arquivo .env criado a partir do .env.example. Preencha os valores e rode o install.sh de novo."
  fi

  if grep -q -e "troque-esta-senha" -e "seu-email@" "$env_file"; then
    fail "O .env ainda tem valores de exemplo. Preencha antes de continuar."
  fi

  chmod 600 "$env_file"
  ok "Arquivo .env configurado"
}

check_msmtp() {
  local home_dir

  home_dir="$(getent passwd "$RUN_USER" | cut -d: -f6)"

  if [[ ! -f "$home_dir/.msmtprc" ]]; then
    warn "Arquivo $home_dir/.msmtprc não encontrado. O relatório diário não será enviado por e-mail até ele ser configurado."
  else
    ok "Configuração do msmtp encontrada"
  fi
}

validate_configs() {
  info "Validando as configurações..."

  docker compose --project-directory "$PROJECT_DIR" config --quiet \
    || fail "docker-compose.yml inválido"

  docker run --rm -v "$PROJECT_DIR/prometheus:/cfg" --entrypoint promtool \
    prom/prometheus:v3.15.0 check config /cfg/prometheus.yml > /dev/null \
    || fail "prometheus.yml inválido"

  ok "Configurações válidas"
}

main() {
  info "Instalando o linux-monitoring-stack em $PROJECT_DIR (usuário: $RUN_USER)"
  check_prerequisites
  prepare_env
  check_msmtp
  validate_configs
}

main "$@"
