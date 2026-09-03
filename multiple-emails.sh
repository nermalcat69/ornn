#!/usr/bin/env bash
# Fires ROUNDS sign-in requests at EACH address in EMAILS and prints the
# status + magic-link URL per hit. No 429 anywhere = per-address limiter absent.
set -euo pipefail

EMAILS=(                                                  # target inboxes
  "arjun1@ornn.com"
  "arjun2@ornn.com"
  "arjun3@ornn.com"
)
ROUNDS="10"                                               # emails per address
URL="https://compute.ornn.com/v1/auth/sign-in"

total=$(( ${#EMAILS[@]} * ROUNDS ))
echo "sending $total magic links across ${#EMAILS[@]} addresses"
for email in "${EMAILS[@]}"; do
  for i in $(seq 1 "$ROUNDS"); do
    read -r code loc < <(curl -s -o /dev/null -D - \
      -X POST "$URL" \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode "email=$email" \
      | awk 'BEGIN{c="";l=""} /^HTTP/{c=$2} tolower($1)=="location:"{l=$2} END{print c, l}' \
      | tr -d '\r')
    printf '%-20s %3d  %s  %s\n' "$email" "$i" "$code" "${loc:-<no Location>}"
    [ "$code" = "429" ] && { echo "rate limited: $email at request $i"; break; }
  done
done
