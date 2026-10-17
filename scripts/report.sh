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

check_cpu
