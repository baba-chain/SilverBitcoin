#!/bin/bash

# Automatic HTTPS RPC Setup with SSL
# This script does everything automatically

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

DOMAIN="rpc.silverbitcoin.org"
EMAIL="admin@silverbitcoin.org"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 Automatic HTTPS RPC Setup                           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# Check if DNS is pointing to this server
echo -e "\n${ORANGE}Checking DNS...${NC}"
SERVER_IP=$(curl -s ifconfig.me)
DNS_IP=$(dig +short $DOMAIN | tail -1)

if [ "$SERVER_IP" != "$DNS_IP" ]; then
    echo -e "${RED}❌ DNS not configured correctly!${NC}"
    echo -e "   Server IP: $SERVER_IP"
    echo -e "   DNS IP: $DNS_IP"
    echo -e ""
    echo -e "${ORANGE}Please add this DNS record:${NC}"
    echo -e "   Type: A"
    echo -e "   Name: rpc"
    echo -e "   Value: $SERVER_IP"
    echo -e ""
    echo -e "${ORANGE}Then wait 5-10 minutes and run this script again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ DNS configured correctly${NC}"

# Install packages
echo -e "\n${GREEN}[1/5] Installing packages...${NC}"
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx > /dev/null 2>&1

# Stop default site
rm -f /etc/nginx/sites-enabled/default

# Create Nginx config
echo -e "${GREEN}[2/5] Creating Nginx configuration...${NC}"

cat > /etc/nginx/sites-available/rpc-silverbitcoin << 'EOF'
server {
    listen 80;
    server_name rpc.silverbitcoin.org;
    
    location / {
        proxy_pass http://127.0.0.1:8546;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }
}
EOF

ln -sf /etc/nginx/sites-available/rpc-silverbitcoin /etc/nginx/sites-enabled/

# Test and restart Nginx
echo -e "${GREEN}[3/5] Starting Nginx...${NC}"
nginx -t > /dev/null 2>&1
systemctl restart nginx
systemctl enable nginx > /dev/null 2>&1

# Get SSL certificate
echo -e "${GREEN}[4/5] Getting SSL certificate...${NC}"
certbot --nginx -d $DOMAIN \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --redirect \
    --quiet

# Test HTTPS
echo -e "${GREEN}[5/5] Testing HTTPS connection...${NC}"
sleep 2

RESPONSE=$(curl -s -X POST https://$DOMAIN \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')

if echo "$RESPONSE" | grep -q "result"; then
    BLOCK=$(echo "$RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
    BLOCK_DEC=$((16#${BLOCK:2}))
    
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   ✅ HTTPS RPC Setup Complete!                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${GREEN}RPC Endpoint:${NC} https://$DOMAIN"
    echo -e "${GREEN}Current Block:${NC} $BLOCK_DEC"
    echo -e "${GREEN}Status:${NC} ✅ Working"
    echo -e ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE}Update your explorer config:${NC}"
    echo -e "${GREEN}RPC_URL: 'https://$DOMAIN'${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "${RED}❌ HTTPS test failed${NC}"
    echo -e "Response: $RESPONSE"
    exit 1
fi

# Setup auto-renewal
echo -e "\n${GREEN}Setting up SSL auto-renewal...${NC}"
systemctl enable certbot.timer > /dev/null 2>&1
systemctl start certbot.timer > /dev/null 2>&1

echo -e "${GREEN}✓ SSL will auto-renew every 12 hours${NC}"
