#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IGNORE_FILE="$SCRIPT_DIR/../config/ignore-patterns.txt"

echo "Relatório do sistema — $(date '+%d/%m/%Y %H:%M')"

check_cpu() {
local cores load load_int status

cores=$(nproc)
load=$(cut -d ' ' -f1 /proc/loadavg)
load_int=${load%.*}

if ((load_int >= cores)); then
 status = "ATENÇÃO"
else
    status="OK"
  fi

echo "CPU: load $load ($cores núcleos) — $status"


}

check_memory() {
local total_kb available_kb available_pct total_mb available_mb status

  total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  available_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

  available_pct=$(( available_kb * 100 / total_kb ))
  total_mb=$(( total_kb / 1024 ))
  available_mb=$(( available_kb / 1024 ))

  if (( available_pct < 15 )); then
    status="ATENÇÃO"
  else
    status="OK"
  fi

  echo "Memória: ${available_mb} MB disponíveis de ${total_mb} MB (${available_pct}%) — $status"

}

check_disk() {
  local used_pct status

  used_pct=$(df --output=pcent / | tail -n 1 | tr -d ' %')

  if (( used_pct >= 85 )); then
    status="ATENÇÃO"
  else
    status="OK"
  fi

  echo "Disco /: ${used_pct}% usado — $status"
}

check_services() {
  local failed count status

  failed=$(systemctl --failed --no-legend --plain | awk '{print $1}')
  count=$(echo -n "$failed" | grep -c '^' || true)

  if (( count > 0 )); then
    status="ATENÇÃO"
    echo "Serviços com falha: $count — $status"
    echo "$failed" | sed 's/^/  - /'
  else
    status="OK"
    echo "Serviços com falha: nenhum — $status"
  fi
}

check_logs() {
  local errors count status

  errors=$(journalctl -p err --since "24 hours ago" --no-pager -q \
    | grep -v -F -f "$IGNORE_FILE" || true)
  count=$(echo -n "$errors" | grep -c '^' || true)

  if (( count > 0 )); then
    status="ATENÇÃO"
    echo "Erros nos logs (24h): $count — $status"
    echo "$errors" | tail -n 5 | sed 's/^/  - /'
  else
    status="OK"
    echo "Erros nos logs (24h): nenhum — $status"
  fi
}

check_updates() {
  local upgradable total security status

  upgradable=$(apt list --upgradable 2>/dev/null | grep -v '^Listing' || true)
  total=$(echo -n "$upgradable" | grep -c '^' || true)
  security=$(echo -n "$upgradable" | grep -c -- '-security' || true)

  if (( total > 0 )); then
    status="ATENÇÃO"
    echo "Atualizações pendentes: $total ($security de segurança) — $status"
  else
    status="OK"
    echo "Atualizações pendentes: nenhuma — $status"
  fi
}

check_cpu
check_memory
check_disk
check_services
check_logs
check_updates
