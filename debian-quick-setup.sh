#!/bin/bash

# SilverBitcoin Blockchain - Debian Quick Setup Script
# Bu script tüm kurulum adımlarını otomatik yapar

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 SilverBitcoin Blockchain - Debian Quick Setup        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo -e "  1. Update system packages"
echo -e "  2. Install Go 1.21.5"
echo -e "  3. Install Node.js 20.x"
echo -e "  4. Clone SilverBitcoin from GitHub"
echo -e "  5. Build Geth binary"
echo -e "  6. Generate validator keys"
echo -e "  7. Initialize nodes"
echo -e "  8. Start validator nodes"
echo -e "  9. Configure firewall"
echo -e "  10. Setup systemd service"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root (sudo)${NC}"
    exit 1
fi

# Step 1: System Update
echo -e "\n${YELLOW}[1/10] Updating system...${NC}"
apt update && apt upgrade -y
apt install -y git curl wget tmux build-essential ufw

# Step 2: Install Go
echo -e "\n${YELLOW}[2/10] Installing Go 1.21.5...${NC}"
if ! command -v go &> /dev/null; then
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    
    # Add to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    
    echo -e "${GREEN}✅ Go installed: $(go version)${NC}"
else
    echo -e "${GREEN}✅ Go already installed: $(go version)${NC}"
fi

# Step 3: Install Node.js
echo -e "\n${YELLOW}[3/10] Installing Node.js 20.x...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    echo -e "${GREEN}✅ Node.js installed: $(node --version)${NC}"
else
    echo -e "${GREEN}✅ Node.js already installed: $(node --version)${NC}"
fi

# Step 4: Clone Project from GitHub
echo -e "\n${YELLOW}[4/10] Cloning SilverBitcoin from GitHub...${NC}"
GITHUB_REPO="https://github.com/baba-chain/SilverBitcoin.git"  

if [ -d "$HOME/SilverBitcoin" ]; then
    echo -e "${YELLOW}⚠️  Directory exists. Resetting to latest version...${NC}"
    cd $HOME/SilverBitcoin
    
    # Reset any local changes
    git fetch origin
    git reset --hard origin/main
    git clean -fd
    
    echo -e "${GREEN}✅ Updated to latest version${NC}"
else
    cd $HOME
    git clone $GITHUB_REPO
    cd SilverBitcoin
    echo -e "${GREEN}✅ Project cloned${NC}"
fi

# Step 5: Build Geth Binary
echo -e "\n${YELLOW}[5/10] Building Geth binary...${NC}"
if [ -d "SilverBitcoin/node_src" ]; then
    cd SilverBitcoin/node_src
    
    # Download Go dependencies
    echo -e "${CYAN}Downloading Go dependencies...${NC}"
    go mod download
    go mod tidy
    
    # Build Geth
    echo -e "${CYAN}Building Geth...${NC}"
    go build -o geth ./cmd/geth
    
    # Move to parent directory
    mv geth ../../
    cd ../..
    chmod +x geth
    
    echo -e "${GREEN}✅ Geth built successfully${NC}"
else
    echo -e "${RED}❌ Geth source not found${NC}"
    exit 1
fi

# Step 6: Generate Validator Keys
echo -e "\n${YELLOW}[6/10] Generating validator keys...${NC}"
if [ -f "generate-node-keys.sh" ]; then
    chmod +x generate-node-keys.sh
    echo "yes" | ./generate-node-keys.sh
    echo -e "${GREEN}✅ Keys generated${NC}"
else
    echo -e "${RED}❌ generate-node-keys.sh not found${NC}"
    exit 1
fi

# Step 7: Initialize Nodes
echo -e "\n${YELLOW}[7/10] Initializing nodes...${NC}"
if [ -f "initialize-nodes.sh" ]; then
    chmod +x initialize-nodes.sh
    ./initialize-nodes.sh
    echo -e "${GREEN}✅ Nodes initialized${NC}"
else
    echo -e "${RED}❌ initialize-nodes.sh not found${NC}"
    exit 1
fi

# Step 8: Start Nodes
echo -e "\n${YELLOW}[8/10] Starting validator nodes...${NC}"
if [ -f "start-all-nodes.sh" ]; then
    chmod +x start-all-nodes.sh
    chmod +x start-node.sh
    ./start-all-nodes.sh
    echo -e "${GREEN}✅ Nodes started${NC}"
else
    echo -e "${RED}❌ start-all-nodes.sh not found${NC}"
    exit 1
fi

# Step 9: Configure Firewall
echo -e "\n${YELLOW}[9/10] Configuring firewall...${NC}"
ufw --force enable
ufw allow 22/tcp
ufw allow 30304:30328/tcp
ufw allow 30304:30328/udp
echo -e "${GREEN}✅ Firewall configured${NC}"

# Step 10: Setup Systemd Service
echo -e "\n${YELLOW}[10/10] Setting up systemd service...${NC}"
cat > /etc/systemd/system/silverbitcoin.service << EOF
[Unit]
Description=SilverBitcoin Blockchain Network
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/start-all-nodes.sh
ExecStop=$(pwd)/stop-all-nodes.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable silverbitcoin
echo -e "${GREEN}✅ Systemd service configured${NC}"

# Final Steps
echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Setup Complete!                                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Next steps:${NC}"
echo -e "1. Start blockchain: ${YELLOW}./start-all-nodes.sh${NC}"
echo -e "2. Check status: ${YELLOW}./node-status.sh${NC}"
echo -e "3. View nodes: ${YELLOW}tmux ls${NC}"
echo -e "4. Attach to node: ${YELLOW}tmux attach -t node1${NC}"
echo -e "5. Start on boot: ${YELLOW}sudo systemctl start silverbitcoin${NC}"

echo -e "\n${CYAN}RPC Endpoints:${NC}"
echo -e "Node01: ${YELLOW}http://$(hostname -I | awk '{print $1}'):8546${NC}"
echo -e "Node02: ${YELLOW}http://$(hostname -I | awk '{print $1}'):8547${NC}"

echo -e "\n${GREEN}🚀 Ready to start blockchain!${NC}"
