#!/bin/bash

# ---------- Configuration ----------
# !!! IMPORTANT: Change URL_BASE to the actual POST endpoint that accepts booking data.
#                Currently it's the GET page – you need to find the real submission URL.
URL_BASE="https://compute.ornn.com/onboarding/schedule"   # <-- REPLACE with correct POST URL
WORKERS=10
LOG_FILE="output.txt"
INTERNAL_DELAY=0
LOG_BODY_LIMIT="full"   # "full" or e.g. 2000

# ---------- Request method and payload ----------
METHOD="POST"   # or "GET"
CONTENT_TYPE="application/json"

# Payload template – adjust fields to match your actual form
# Example for JSON:
PAYLOAD_TEMPLATE='{"date": "%s", "time": "%s", "timezone": "UTC"}'

# Example for form-urlencoded (uncomment and comment the JSON one):
# CONTENT_TYPE="application/x-www-form-urlencoded"
# PAYLOAD_TEMPLATE="date=%s&time=%s&timezone=UTC"

# ---------- Portable random date generator (works on macOS & Linux) ----------
generate_payload() {
    # Random days between 1 and 30
    local rand_days=$((RANDOM % 30 + 1))
    local date_str=""
    local time_str=""
    
    # Detect OS and use appropriate date command
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: use -v to add days
        date_str=$(date -v+${rand_days}d +"%Y-%m-%d" 2>/dev/null)
    else
        # Linux / GNU date
        date_str=$(date -d "+$rand_days days" +"%Y-%m-%d" 2>/dev/null)
    fi
    
    # Fallback if date command failed (use perl)
    if [[ -z "$date_str" ]]; then
        date_str=$(perl -e "use POSIX; print strftime('%Y-%m-%d', localtime(time + $rand_days * 86400));")
    fi
    
    # Random time between 09:00 and 17:50 (multiples of 10)
    local hour=$((RANDOM % 8 + 9))
    local minute=$(( (RANDOM % 6) * 10 ))
    time_str=$(printf "%02d:%02d" $hour $minute)
    
    # Build payload
    printf "$PAYLOAD_TEMPLATE" "$date_str" "$time_str"
}

# ---------- Base curl headers ----------
CURL_HEADERS="\
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cache-control: no-cache' \
  -b '_gcl_au=1.1.1479811518.1788636833; __Secure-better-auth.session_token=1e05bc79997c439f97a4e3178567a04218ca2343eb9d434d95afa9039416dc20.fIN+ffS2mdg1+uPwO+3NVUv32lgqu0/ZxbYnN7uWfIc=; ph_phc_oAshQThWSEgFFv7DKMTR4ri2f4UoPd5JgzLE3yQdr7xh_posthog=%7B%22%24device_id%22%3A%2201a07310-3c1e-7ab0-8378-0fee83587ff5%22%2C%22distinct_id%22%3A%22ac820bb2-8ae1-4069-bd43-545b0aef8a28%22%2C%22%24sesid%22%3A%5B1788639043941%2C%2201a07310-3c3f-7247-9c58-1523ae7c901f%22%2C1788636838974%5D%2C%22%24epp%22%3Atrue%2C%22%24initial_person_info%22%3A%7B%22r%22%3A%22https%3A%2F%2Fornn.com%2F%22%2C%22u%22%3A%22https%3A%2F%2Fcompute.ornn.com%2F%22%7D%2C%22%24user_state%22%3A%22identified%22%7D' \
  -H 'pragma: no-cache' \
  -H 'priority: u=0, i' \
  -H 'referer: https://compute.ornn.com/onboarding' \
  -H 'sec-ch-ua: \"Chromium\";v=\"152\", \"Not?A_Brand\";v=\"24\", \"Google Chrome\";v=\"152\"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: \"macOS\"' \
  -H 'sec-fetch-dest: document' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1'"

# ---------- Logging ----------
log() {
    local worker_id=$1
    local msg=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "[%s] [Worker %2d] %s\n" "$timestamp" "$worker_id" "$msg"
}

# ---------- Worker ----------
worker() {
    local id=$1
    local count=0
    local ua_versions=("537.36" "537.36" "537.36" "537.36" "537.36" "538.0" "539.0" "540.0")

    while true; do
        count=$((count + 1))
        local rand_param=$((RANDOM % 1000000))
        local url_with_rand="${URL_BASE}?_r=${rand_param}"
        local ua_version=${ua_versions[$((RANDOM % ${#ua_versions[@]}))]}
        local user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.${ua_version} Safari/537.36"

        local payload=$(generate_payload)

        local header_file=$(mktemp)
        local body_file=$(mktemp)

        if [[ "$METHOD" == "POST" ]]; then
            CMD="curl --request POST --url '$url_with_rand' \
              ${CURL_HEADERS} \
              -H 'user-agent: ${user_agent}' \
              -H 'content-type: ${CONTENT_TYPE}' \
              -d '${payload}' \
              -D '$header_file' \
              -o '$body_file' \
              -w '%{http_code}' -s"
        else
            CMD="curl --url '$url_with_rand' \
              ${CURL_HEADERS} \
              -H 'user-agent: ${user_agent}' \
              -D '$header_file' \
              -o '$body_file' \
              -w '%{http_code}' -s"
        fi

        http_code=$(eval "$CMD")
        curl_exit=$?

        headers=$(cat "$header_file" 2>/dev/null || echo "[No headers]")
        rm -f "$header_file"
        if [[ -f "$body_file" ]]; then
            if [[ "$LOG_BODY_LIMIT" == "full" ]]; then
                response_body=$(cat "$body_file")
            else
                response_body=$(head -c "$LOG_BODY_LIMIT" "$body_file")
                if [[ $(wc -c < "$body_file") -gt "$LOG_BODY_LIMIT" ]]; then
                    response_body="${response_body}\n... [truncated]"
                fi
            fi
            rm -f "$body_file"
        else
            response_body="[No body]"
        fi

        if [[ $curl_exit -eq 0 ]]; then
            if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
                status="✅ SUCCESS"
            else
                status="⚠️  RESPONSE (non-2xx)"
            fi
            meta="Attempt #${count} | rand=${rand_param} | HTTP ${http_code} | curl 0 | ${status} | payload: ${payload}"
        else
            meta="Attempt #${count} | rand=${rand_param} | HTTP (none) | curl exit ${curl_exit} | ❌ FAILED | payload: ${payload}"
        fi

        log_line="[$(date '+%Y-%m-%d %H:%M:%S')] [Worker $id] $meta"
        echo "$log_line"
        echo "---- RESPONSE HEADERS START ----"
        echo "$headers"
        echo "---- RESPONSE HEADERS END ----"
        echo "---- RESPONSE BODY START ----"
        echo "$response_body"
        echo "---- RESPONSE BODY END ----"

        if [[ -n "$LOG_FILE" ]]; then
            echo "$log_line" >> "$LOG_FILE"
            echo "---- RESPONSE HEADERS START ----" >> "$LOG_FILE"
            echo "$headers" >> "$LOG_FILE"
            echo "---- RESPONSE HEADERS END ----" >> "$LOG_FILE"
            echo "---- RESPONSE BODY START ----" >> "$LOG_FILE"
            echo "$response_body" >> "$LOG_FILE"
            echo "---- RESPONSE BODY END ----" >> "$LOG_FILE"
        fi

        if [[ "$INTERNAL_DELAY" -gt 0 ]]; then
            sleep "$INTERNAL_DELAY"
        fi
    done
}

# ---------- Cleanup ----------
cleanup() {
    echo -e "\n[Main] Shutting down all workers..."
    jobs -p | xargs kill 2>/dev/null
    wait 2>/dev/null
    echo "[Main] All workers stopped. Exiting."
    exit 0
}
trap cleanup SIGINT SIGTERM

# ---------- Start ----------
if [[ -n "$LOG_FILE" ]]; then
    echo "=== Parallel curl log (POST with data) started at $(date) ===" > "$LOG_FILE"
    echo "Workers: $WORKERS, Delay: $INTERNAL_DELAY s" >> "$LOG_FILE"
    echo "Method: $METHOD, Content-Type: $CONTENT_TYPE" >> "$LOG_FILE"
    echo "URL: $URL_BASE" >> "$LOG_FILE"
    echo "---------------------------------------------" >> "$LOG_FILE"
fi

echo "[Main] Starting $WORKERS parallel workers. Press Ctrl+C to stop."

for ((i=1; i<=WORKERS; i++)); do
    worker "$i" &
done

wait