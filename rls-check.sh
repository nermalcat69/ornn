#!/bin/bash
# Supabase RLS exposure check for id.ornn.com (project mkafwqyhscdzciywoatu)
# anon key is public (from data.ornn.com JS bundle). Read-only GETs.
ANON='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rYWZ3cXloc2NkemNpeXdvYXR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyOTE5MDgsImV4cCI6MjA4MDg2NzkwOH0.pLdo0r6WEUkJ36o-nlFMVbLGhxuHAAtnfIZvXMGSVZQ'
BASE='https://id.ornn.com/rest/v1'

# Guessed table names — extend from the real list (Supabase dashboard > Database > Tables,
# or grep .from(' / rest/v1/ in the data.ornn.com and compute.ornn.com JS bundles).
TABLES=(
  profiles users accounts organizations orgs organization_members members team_members teams
  onboarding onboarding_intake intake waitlist signups subscribers leads contacts invites
  billing invoices subscriptions api_keys ssh_keys reservations bids listings
  gpu_index index_history daily_index markets news forward_shape notifications audit_log
)

printf '%-28s %-6s %s\n' TABLE HTTP RESULT
for t in "${TABLES[@]}"; do
  r=$(curl -s -m 10 -w '|%{http_code}' \
        -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
        "$BASE/$t?select=*&limit=1")
  code=${r##*|}; body=${r%|*}
  case "$code" in
    200) verdict="!!! EXPOSED (RLS off or permissive)  ${body:0:120}";;
    401|403) verdict="ok (blocked)";;
    404) verdict="no such table";;
    *)   verdict="? ${body:0:120}";;
  esac
  printf '%-28s %-6s %s\n' "$t" "$code" "$verdict"
done

# Also check RPC endpoints the app calls (public-index/* on data.ornn.com are Next API routes,
# but they may wrap PG functions):
for fn in daily_index forward_shape gpu_types_free token_types_free otpi; do
  code=$(curl -s -m10 -o /dev/null -w '%{http_code}' -X POST \
    -H "apikey: $ANON" -H "Authorization: Bearer $ANON" -H 'Content-Type: application/json' \
    -d '{}' "$BASE/rpc/$fn")
  echo "rpc/$fn -> $code"
done
