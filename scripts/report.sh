#!/usr/bin/env bash

set -euo pipefail

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

check_cpu
check_memory   




