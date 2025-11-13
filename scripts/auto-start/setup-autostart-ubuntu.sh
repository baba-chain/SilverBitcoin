#!/bin/bash

# SilverBitcoin - Auto-Start Service Setup for Ubuntu 24.04
# Creates systemd service to automatically start all nodes after reboot

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 SilverBitcoin Auto-Start Service Setup               ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root or with sudo${NC}"
    echo -e "${YELLOW}Usage: sudo ./setup-autostart-ubuntu.sh${NC}"
    exit 1
fi

# Get the actual user (not root if using sudo)
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

echo -e "${YELLOW}Detected user: $ACTUAL_USER${NC}"
echo -e "${YELLOW}Home directory: $ACTUAL_HOME${NC}"
echo ""

# Find SilverBitcoin directory
BLOCKCHAIN_DIR=""
if [ -d "$ACTUAL_HOME/Desktop/SilverBitcoin" ]; then
    BLOCKCHAIN_DIR="$ACTUAL_HOME/Desktop/SilverBitcoin"
elif [ -d "$ACTUAL_HOME/SilverBitcoin" ]; then
    BLOCKCHAIN_DIR="$ACTUAL_HOME/SilverBitcoin"
elif [ -d "/opt/SilverBitcoin" ]; then
    BLOCKCHAIN_DIR="/opt/SilverBitcoin"
else
    echo -e "${RED}❌ SilverBitcoin project directory not found!${NC}"
    echo -e "${YELLOW}Searched in:${NC}"
    echo -e "  - $ACTUAL_HOME/Desktop/SilverBitcoin"
    echo -e "  - $ACTUAL_HOME/SilverBitcoin"
    echo -e "  - /opt/SilverBitcoin"
    echo ""
    read -p "Enter full path to SilverBitcoin project directory: " BLOCKCHAIN_DIR
    
    if [ ! -d "$BLOCKCHAIN_DIR" ]; then
        echo -e "${RED}❌ Directory not found: $BLOCKCHAIN_DIR${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Found blockchain directory: $BLOCKCHAIN_DIR${NC}"
echo ""

# Check required files
if [ ! -f "$BLOCKCHAIN_DIR/scripts/node-management/start-all-nodes.sh" ]; then
    echo -e "${RED}❌ start-all-nodes.sh not found in $BLOCKCHAIN_DIR/scripts/node-management/${NC}"
    exit 1
fi

if [ ! -f "$BLOCKCHAIN_DIR/scripts/node-management/stop-all-nodes.sh" ]; then
    echo -e "${RED}❌ stop-all-nodes.sh not found in $BLOCKCHAIN_DIR/scripts/node-management/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Required scripts found${NC}"
echo ""

# Check if geth exists
GETH_PATH=""
if [ -f "$BLOCKCHAIN_DIR/geth" ]; then
    GETH_PATH="$BLOCKCHAIN_DIR/geth"
    echo -e "${GREEN}✓ Local geth binary found${NC}"
elif command -v geth &> /dev/null; then
    GETH_PATH=$(which geth)
    echo -e "${GREEN}✓ System geth found: $GETH_PATH${NC}"
else
    echo -e "${YELLOW}⚠ Geth binary not found${NC}"
    echo -e "${YELLOW}Service will be created but may fail to start${NC}"
fi

echo ""

# Check if nodes directory exists
if [ ! -d "$BLOCKCHAIN_DIR/nodes" ]; then
    echo -e "${YELLOW}⚠ nodes/ directory not found${NC}"
    echo -e "${YELLOW}You need to run generate-node-keys.sh first${NC}"
    read -p "Continue anyway? (yes/no): " continue_anyway
    if [ "$continue_anyway" != "yes" ] && [ "$continue_anyway" != "y" ]; then
        exit 0
    fi
fi

echo ""
echo -e "${CYAN}Creating systemd service...${NC}"
echo ""

# Create systemd service file
SERVICE_FILE="/etc/systemd/system/silverbitcoin-nodes.service"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=SilverBitcoin Validator Nodes
Documentation=https://github.com/baba-chain/Blockchain
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=$ACTUAL_USER
Group=$ACTUAL_USER
WorkingDirectory=$BLOCKCHAIN_DIR

# Wait for network to be ready
ExecStartPre=/bin/sleep 10

# Start all nodes
ExecStart=$BLOCKCHAIN_DIR/scripts/node-management/start-all-nodes.sh

# Stop all nodes
ExecStop=$BLOCKCHAIN_DIR/scripts/node-management/stop-all-nodes.sh

# Restart policy
Restart=on-failure
RestartSec=30
TimeoutStartSec=300
TimeoutStopSec=120

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=silverbitcoin

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Service file created: $SERVICE_FILE${NC}"
echo ""

# Create a health check script
HEALTH_CHECK_SCRIPT="$BLOCKCHAIN_DIR/health-check.sh"

cat > "$HEALTH_CHECK_SCRIPT" << 'EOF'
#!/bin/bash

# SilverBitcoin Health Check Script
# Checks if nodes are running and restarts if needed

RUNNING_NODES=$(tmux ls 2>/dev/null | grep -c "node" || echo "0")

if [ "$RUNNING_NODES" -lt 10 ]; then
    echo "$(date): Only $RUNNING_NODES nodes running, restarting..."
    systemctl restart silverbitcoin-nodes
else
    echo "$(date): $RUNNING_NODES nodes running - OK"
fi
EOF

chmod +x "$HEALTH_CHECK_SCRIPT"
chown $ACTUAL_USER:$ACTUAL_USER "$HEALTH_CHECK_SCRIPT"

echo -e "${GREEN}✓ Health check script created: $HEALTH_CHECK_SCRIPT${NC}"
echo ""

# Create a systemd timer for health checks (optional)
read -p "Create automatic health check timer? (runs every 10 minutes) (yes/no): " create_timer

if [ "$create_timer" = "yes" ] || [ "$create_timer" = "y" ]; then
    TIMER_FILE="/etc/systemd/system/silverbitcoin-healthcheck.timer"
    TIMER_SERVICE="/etc/systemd/system/silverbitcoin-healthcheck.service"
    
    cat > "$TIMER_SERVICE" << EOF
[Unit]
Description=SilverBitcoin Health Check
After=silverbitcoin-nodes.service

[Service]
Type=oneshot
User=$ACTUAL_USER
ExecStart=$HEALTH_CHECK_SCRIPT
StandardOutput=journal
StandardError=journal
EOF

    cat > "$TIMER_FILE" << EOF
[Unit]
Description=SilverBitcoin Health Check Timer
Requires=silverbitcoin-healthcheck.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=10min
Unit=silverbitcoin-healthcheck.service

[Install]
WantedBy=timers.target
EOF

    echo -e "${GREEN}✓ Health check timer created${NC}"
    systemctl daemon-reload
    systemctl enable silverbitcoin-healthcheck.timer
    systemctl start silverbitcoin-healthcheck.timer
    echo -e "${GREEN}✓ Health check timer enabled${NC}"
    echo ""
fi

# Reload systemd
echo -e "${CYAN}Reloading systemd...${NC}"
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd reloaded${NC}"
echo ""

# Enable the service
echo -e "${CYAN}Enabling service...${NC}"
systemctl enable silverbitcoin-nodes.service
echo -e "${GREEN}✓ Service enabled${NC}"
echo ""

# Ask if user wants to start now
read -p "Start the service now? (yes/no): " start_now

if [ "$start_now" = "yes" ] || [ "$start_now" = "y" ]; then
    echo -e "${CYAN}Starting service...${NC}"
    systemctl start silverbitcoin-nodes.service
    sleep 5
    systemctl status silverbitcoin-nodes.service --no-pager
    echo ""
fi

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Auto-Start Service Setup Complete!                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Service Configuration:${NC}"
echo -e "  Name: ${CYAN}silverbitcoin-nodes${NC}"
echo -e "  User: ${CYAN}$ACTUAL_USER${NC}"
echo -e "  Directory: ${CYAN}$BLOCKCHAIN_DIR${NC}"
echo -e "  Auto-start: ${GREEN}Enabled${NC}"
echo ""

echo -e "${YELLOW}Service Management Commands:${NC}"
echo -e "  Start:   ${CYAN}sudo systemctl start silverbitcoin-nodes${NC}"
echo -e "  Stop:    ${CYAN}sudo systemctl stop silverbitcoin-nodes${NC}"
echo -e "  Restart: ${CYAN}sudo systemctl restart silverbitcoin-nodes${NC}"
echo -e "  Status:  ${CYAN}sudo systemctl status silverbitcoin-nodes${NC}"
echo -e "  Logs:    ${CYAN}sudo journalctl -u silverbitcoin-nodes -f${NC}"
echo -e "  Disable: ${CYAN}sudo systemctl disable silverbitcoin-nodes${NC}"
echo ""

if [ "$create_timer" = "yes" ] || [ "$create_timer" = "y" ]; then
    echo -e "${YELLOW}Health Check Commands:${NC}"
    echo -e "  Status:  ${CYAN}sudo systemctl status silverbitcoin-healthcheck.timer${NC}"
    echo -e "  Logs:    ${CYAN}sudo journalctl -u silverbitcoin-healthcheck -f${NC}"
    echo -e "  Disable: ${CYAN}sudo systemctl disable silverbitcoin-healthcheck.timer${NC}"
    echo ""
fi

echo -e "${YELLOW}Testing:${NC}"
echo -e "  1. Check status: ${CYAN}sudo systemctl status silverbitcoin-nodes${NC}"
echo -e "  2. View logs:    ${CYAN}sudo journalctl -u silverbitcoin-nodes -n 50${NC}"
echo -e "  3. Test reboot:  ${CYAN}sudo reboot${NC}"
echo ""

echo -e "${GREEN}✅ Your nodes will now start automatically after server reboots!${NC}"
