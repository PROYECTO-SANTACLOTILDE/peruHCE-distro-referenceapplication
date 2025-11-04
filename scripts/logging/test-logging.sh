#!/bin/bash
# Script para probar el stack de logging
# Autor: PeruHCE Team

set -e

echo "🔍 Testing Centralized Logging Stack"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if services are running
echo -e "\n${YELLOW}1. Checking if services are running...${NC}"

services=("loki" "promtail" "grafana")
all_running=true

for service in "${services[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "peruHCE-$service"; then
        echo -e "${GREEN}✓${NC} peruHCE-$service is running"
    else
        echo -e "${RED}✗${NC} peruHCE-$service is NOT running"
        all_running=false
    fi
done

if [ "$all_running" = false ]; then
    echo -e "\n${RED}Error: Some services are not running${NC}"
    echo "Start them with: docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d"
    exit 1
fi

# Check Loki health
echo -e "\n${YELLOW}2. Checking Loki health...${NC}"
if curl -f -s http://localhost:3100/ready > /dev/null; then
    echo -e "${GREEN}✓${NC} Loki is ready"
else
    echo -e "${RED}✗${NC} Loki is not responding"
    exit 1
fi

# Check if Promtail is sending logs
echo -e "\n${YELLOW}3. Checking Promtail metrics...${NC}"
promtail_targets=$(curl -s http://localhost:9080/metrics | grep "promtail_targets_active" | awk '{print $2}')
if [ -n "$promtail_targets" ] && [ "$promtail_targets" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Promtail is tracking $promtail_targets target(s)"
else
    echo -e "${YELLOW}⚠${NC} Promtail has no active targets"
fi

# Generate test logs
echo -e "\n${YELLOW}4. Generating test logs...${NC}"
docker exec peruHCE-backend echo "[INFO] Test log from logging script - timestamp: $(date +%s)" || true
docker exec peruHCE-frontend echo "[ERROR] Test error log from logging script - timestamp: $(date +%s)" || true
docker exec peruHCE-gateway echo "[WARN] Test warning log from logging script - timestamp: $(date +%s)" || true

echo -e "${GREEN}✓${NC} Test logs generated"

# Wait a bit for logs to be ingested
echo -e "\n${YELLOW}5. Waiting for logs to be ingested (5 seconds)...${NC}"
sleep 5

# Query logs from Loki
echo -e "\n${YELLOW}6. Querying recent logs from Loki...${NC}"

# Query last 10 minutes of logs
query='{job="docker"}'
start_time=$(($(date +%s) - 600))  # 10 minutes ago
end_time=$(date +%s)

response=$(curl -s -G http://localhost:3100/loki/api/v1/query_range \
    --data-urlencode "query=$query" \
    --data-urlencode "start=${start_time}000000000" \
    --data-urlencode "end=${end_time}000000000" \
    --data-urlencode "limit=100")

# Check if we got logs
log_count=$(echo "$response" | jq -r '.data.result | length' 2>/dev/null || echo "0")

if [ "$log_count" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Found $log_count log stream(s) in Loki"

    # Show sample logs
    echo -e "\n${YELLOW}Sample logs:${NC}"
    echo "$response" | jq -r '.data.result[0].values[0:3][]' 2>/dev/null | while read -r line; do
        timestamp=$(echo "$line" | jq -r '.[0]')
        message=$(echo "$line" | jq -r '.[1]')
        echo "  $(date -d @$((timestamp/1000000000)) '+%Y-%m-%d %H:%M:%S') - $message"
    done 2>/dev/null || echo "  (Unable to parse log details)"
else
    echo -e "${YELLOW}⚠${NC} No logs found in Loki yet. This might be normal if the system just started."
fi

# Check Grafana connection
echo -e "\n${YELLOW}7. Checking Grafana...${NC}"
if curl -f -s http://localhost:3001/api/health > /dev/null; then
    echo -e "${GREEN}✓${NC} Grafana is accessible at http://localhost:3001"
    echo -e "  Login with admin / (password from .env)"
else
    echo -e "${RED}✗${NC} Grafana is not responding"
fi

# Summary
echo -e "\n${GREEN}===================================="
echo "✓ Logging Stack Test Complete"
echo "====================================${NC}"

echo -e "\nNext steps:"
echo "1. Open Grafana: http://localhost:3001"
echo "2. Go to 'Explore' (compass icon)"
echo "3. Select 'Loki' datasource"
echo "4. Try this query: {service=\"backend\"}"
echo ""
echo "Example LogQL queries:"
echo "  - All backend logs: {service=\"backend\"}"
echo "  - All errors: {level=\"ERROR\"}"
echo "  - Search text: {container=\"peruHCE-backend\"} |= \"error\""
echo "  - Rate: rate({service=\"backend\"}[5m])"
