#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# shellcheck source=../.env.example
source "$ENV_FILE"

report=$("$SCRIPT_DIR/report.sh")
echo "$report"

if grep -q "ATENÇÃO" <<< "$report"; then
  subject="[ATENCAO] Relatorio do sistema - $(hostname)"
else
  subject="[OK] Relatorio do sistema - $(hostname)"
fi

printf "Subject: %s\nContent-Type: text/plain; charset=UTF-8\n\n%s\n" \
  "$subject" "$report" | msmtp "$REPORT_EMAIL"
