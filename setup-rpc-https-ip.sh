#!/bin/bash

# Setup HTTPS RPC with self-signed certificate (no domain needed)
# Run this on your server (34.122.141.167)

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔒 HTTPS RPC Setup (Self-Signed Certificate)           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)
echo -e "${GREEN}Server IP: $SERVER_IP${NC}"

# Install Nginx
echo -e "\n${GREEN}[1/5] Installing Nginx...${NC}"
apt-get update -qq
apt-get install -y -qq nginx openssl > /dev/null 2>&1

# Create SSL certificate
echo -e "${GREEN}[2/5] Creating self-signed SSL certificate...${NC}"
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/rpc.key \
    -out /etc/nginx/ssl/rpc.crt \
    -subj "/C=US/ST=State/L=City/O=SilverBitcoin/CN=$SERVER_IP" \
    > /dev/null 2>&1

# Create Nginx config
echo -e "${GREEN}[3/5] Creating Nginx configuration...${NC}"

cat > /etc/nginx/sites-available/rpc-silverbitcoin << EOF
server {
    listen 443 ssl http2;
    server_name $SERVER_IP;
    
    # SSL certificates
    ssl_certificate /etc/nginx/ssl/rpc.crt;
    ssl_certificate_key /etc/nginx/ssl/rpc.key;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # CORS headers
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type' always;
    
    # Handle OPTIONS requests
    if (\$request_method = 'OPTIONS') {
        return 204;
    }
    
    # Proxy to local RPC
    location / {
        proxy_pass http://127.0.0.1:8546;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name $SERVER_IP;
    return 301 https://\$server_name\$request_uri;
}
EOF

# Enable site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/rpc-silverbitcoin /etc/nginx/sites-enabled/

# Test and restart Nginx
echo -e "${GREEN}[4/5] Starting Nginx...${NC}"
nginx -t > /dev/null 2>&1
systemctl restart nginx
systemctl enable nginx > /dev/null 2>&1

# Test HTTPS
echo -e "${GREEN}[5/5] Testing HTTPS connection...${NC}"
sleep 2

RESPONSE=$(curl -k -s -X POST https://$SERVER_IP \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')

if echo "$RESPONSE" | grep -q "result"; then
    BLOCK=$(echo "$RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
    BLOCK_DEC=$((16#${BLOCK:2}))
    
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   ✅ HTTPS RPC Setup Complete!                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${GREEN}RPC Endpoint:${NC} https://$SERVER_IP"
    echo -e "${GREEN}Current Block:${NC} $BLOCK_DEC"
    echo -e "${GREEN}Status:${NC} ✅ Working"
    echo -e ""
    echo -e "${ORANGE}⚠️  Note: Self-signed certificate${NC}"
    echo -e "   Browsers will show security warning"
    echo -e "   Click 'Advanced' → 'Proceed anyway'"
    echo -e ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE}Update your explorer config:${NC}"
    echo -e "${GREEN}RPC_URL: 'https://$SERVER_IP'${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "${RED}❌ HTTPS test failed${NC}"
    echo -e "Response: $RESPONSE"
    exit 1
fi

echo -e "\n${GREEN}Test command:${NC}"
echo -e "curl -k -X POST https://$SERVER_IP -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}'"
