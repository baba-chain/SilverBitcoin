#!/bin/bash

# SilverBitcoin - Remove Auto-Start Service

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🗑️  Remove SilverBitcoin Auto-Start Service              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root or with sudo${NC}"
    echo -e "${YELLOW}Usage: sudo ./remove-autostart.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}This will remove the auto-start service.${NC}"
echo -e "${YELLOW}Your nodes will NOT start automatically after reboot.${NC}"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
    echo -e "${RED}Cancelled.${NC}"
    exit 0
fi

echo ""

# Stop and disable main service
if systemctl is-active --quiet silverbitcoin-nodes; then
    echo -e "${YELLOW}Stopping service...${NC}"
    systemctl stop silverbitcoin-nodes
    echo -e "${GREEN}✓ Service stopped${NC}"
fi

if systemctl is-enabled --quiet silverbitcoin-nodes 2>/dev/null; then
    echo -e "${YELLOW}Disabling service...${NC}"
    systemctl disable silverbitcoin-nodes
    echo -e "${GREEN}✓ Service disabled${NC}"
fi

# Remove service file
if [ -f "/etc/systemd/system/silverbitcoin-nodes.service" ]; then
    echo -e "${YELLOW}Removing service file...${NC}"
    rm /etc/systemd/system/silverbitcoin-nodes.service
    echo -e "${GREEN}✓ Service file removed${NC}"
fi

# Stop and disable health check timer
if systemctl is-active --quiet silverbitcoin-healthcheck.timer 2>/dev/null; then
    echo -e "${YELLOW}Stopping health check timer...${NC}"
    systemctl stop silverbitcoin-healthcheck.timer
    echo -e "${GREEN}✓ Timer stopped${NC}"
fi

if systemctl is-enabled --quiet silverbitcoin-healthcheck.timer 2>/dev/null; then
    echo -e "${YELLOW}Disabling health check timer...${NC}"
    systemctl disable silverbitcoin-healthcheck.timer
    echo -e "${GREEN}✓ Timer disabled${NC}"
fi

# Remove timer files
if [ -f "/etc/systemd/system/silverbitcoin-healthcheck.timer" ]; then
    rm /etc/systemd/system/silverbitcoin-healthcheck.timer
    echo -e "${GREEN}✓ Timer file removed${NC}"
fi

if [ -f "/etc/systemd/system/silverbitcoin-healthcheck.service" ]; then
    rm /etc/systemd/system/silverbitcoin-healthcheck.service
    echo -e "${GREEN}✓ Health check service file removed${NC}"
fi

# Reload systemd
echo -e "${YELLOW}Reloading systemd...${NC}"
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true
echo -e "${GREEN}✓ Systemd reloaded${NC}"

echo ""
echo -e "${GREEN}✅ Auto-start service removed successfully!${NC}"
echo ""
echo -e "${YELLOW}Note: Your nodes are still installed, just not auto-starting.${NC}"
echo -e "${YELLOW}To start nodes manually: ./start-all-nodes.sh${NC}"
