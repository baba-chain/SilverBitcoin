#!/bin/bash

# SilverBitcoin Troubleshooting Script
# Checks system requirements and common issues

# Get the project root directory (2 levels up from scripts/maintenance/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔍 SilverBitcoin Troubleshooting                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check OS
echo -e "${YELLOW}System Information:${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "  OS: ${GREEN}$NAME $VERSION${NC}"
else
    echo -e "  OS: ${RED}Unknown${NC}"
fi
echo -e "  Kernel: ${GREEN}$(uname -r)${NC}"
echo ""

# Check Go
echo -e "${YELLOW}Go Installation:${NC}"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    echo -e "  ${GREEN}✓ Go installed: $GO_VERSION${NC}"
    echo -e "  Path: $(which go)"
else
    echo -e "  ${RED}✗ Go not found${NC}"
    echo -e "  ${YELLOW}Install: sudo apt install golang-1.22${NC}"
fi
echo ""

# Check Geth
echo -e "${YELLOW}Geth Binary:${NC}"
if [ -f "./geth" ]; then
    echo -e "  ${GREEN}✓ Local geth found${NC}"
    ./geth version 2>/dev/null | head -3 || echo -e "  ${YELLOW}Cannot get version${NC}"
elif command -v geth &> /dev/null; then
    echo -e "  ${GREEN}✓ System geth found${NC}"
    geth version 2>/dev/null | head -3
else
    echo -e "  ${RED}✗ Geth not found${NC}"
    echo -e "  ${YELLOW}Build: cd Blockchain/node_src && go build -o geth ./cmd/geth${NC}"
fi
echo ""

# Check tmux
echo -e "${YELLOW}Tmux:${NC}"
if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V)
    echo -e "  ${GREEN}✓ $TMUX_VERSION${NC}"
else
    echo -e "  ${RED}✗ Tmux not found${NC}"
    echo -e "  ${YELLOW}Install: sudo apt install tmux${NC}"
fi
echo ""

# Check Python
echo -e "${YELLOW}Python:${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "  ${GREEN}✓ $PYTHON_VERSION${NC}"
else
    echo -e "  ${RED}✗ Python3 not found${NC}"
    echo -e "  ${YELLOW}Install: sudo apt install python3${NC}"
fi
echo ""

# Check required packages
echo -e "${YELLOW}Required Packages:${NC}"
PACKAGES="git build-essential curl wget openssl libgmp-dev libssl-dev pkg-config"
for pkg in $PACKAGES; do
    if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
        echo -e "  ${GREEN}✓ $pkg${NC}"
    else
        echo -e "  ${RED}✗ $pkg${NC}"
    fi
done
echo ""

# Check genesis.json
echo -e "${YELLOW}Genesis Configuration:${NC}"
if [ -f "genesis.json" ]; then
    echo -e "  ${GREEN}✓ genesis.json found${NC}"
    ALLOC_COUNT=$(grep -o '"0x[0-9a-fA-F]\{40\}"' genesis.json | wc -l)
    echo -e "  Allocated addresses: $ALLOC_COUNT"
elif [ -f "Blockchain/genesis.json" ]; then
    echo -e "  ${YELLOW}⚠ genesis.json in SilverBitcoin/ directory${NC}"
    echo -e "  ${YELLOW}Copy to root: cp Blockchain/genesis.json .${NC}"
else
    echo -e "  ${RED}✗ genesis.json not found${NC}"
fi
echo ""

# Check node directories
echo -e "${YELLOW}Node Directories:${NC}"
if [ -d "nodes" ]; then
    NODE_COUNT=$(ls -d nodes/Node* 2>/dev/null | wc -l)
    echo -e "  ${GREEN}✓ $NODE_COUNT node directories found${NC}"
    
    # Check if initialized
    INIT_COUNT=$(find nodes/Node*/geth/chaindata -type d 2>/dev/null | wc -l)
    echo -e "  Initialized: $INIT_COUNT/$NODE_COUNT"
    
    # Check if keys exist
    KEY_COUNT=$(find nodes/Node*/keystore -type d ! -empty 2>/dev/null | wc -l)
    echo -e "  With keys: $KEY_COUNT/$NODE_COUNT"
else
    echo -e "  ${RED}✗ nodes/ directory not found${NC}"
    echo -e "  ${YELLOW}Run: ./generate-node-keys.sh${NC}"
fi
echo ""

# Check running nodes
echo -e "${YELLOW}Running Nodes:${NC}"
if command -v tmux &> /dev/null; then
    RUNNING=$(tmux ls 2>/dev/null | grep -c "node" || echo "0")
    if [ "$RUNNING" -gt 0 ]; then
        echo -e "  ${GREEN}✓ $RUNNING nodes running${NC}"
        tmux ls 2>/dev/null | grep "node" | head -5
    else
        echo -e "  ${YELLOW}No nodes running${NC}"
    fi
else
    echo -e "  ${YELLOW}Cannot check (tmux not installed)${NC}"
fi
echo ""

# Check ports
echo -e "${YELLOW}Port Availability:${NC}"
if command -v ss &> /dev/null; then
    USED_PORTS=$(ss -tuln | grep -E ":(8546|8547|8548|30304|30305|30306)" | wc -l)
    if [ "$USED_PORTS" -gt 0 ]; then
        echo -e "  ${GREEN}$USED_PORTS blockchain ports in use${NC}"
    else
        echo -e "  ${YELLOW}No blockchain ports in use${NC}"
    fi
elif command -v netstat &> /dev/null; then
    USED_PORTS=$(netstat -tuln | grep -E ":(8546|8547|8548|30304|30305|30306)" | wc -l)
    if [ "$USED_PORTS" -gt 0 ]; then
        echo -e "  ${GREEN}$USED_PORTS blockchain ports in use${NC}"
    else
        echo -e "  ${YELLOW}No blockchain ports in use${NC}"
    fi
else
    echo -e "  ${YELLOW}Cannot check (ss/netstat not available)${NC}"
fi
echo ""

# Check disk space
echo -e "${YELLOW}Disk Space:${NC}"
df -h . | tail -1 | awk '{print "  Available: "$4" ("$5" used)"}'
echo ""

# Recommendations
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   💡 Recommendations                                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "./geth" ] && ! command -v geth &> /dev/null; then
    echo -e "${YELLOW}1. Build Geth:${NC}"
    echo -e "   cd Blockchain/node_src"
    echo -e "   go build -o geth ./cmd/geth"
    echo -e "   mv geth ../../"
    echo ""
fi

if [ ! -d "nodes" ] || [ $(ls -d nodes/Node* 2>/dev/null | wc -l) -eq 0 ]; then
    echo -e "${YELLOW}2. Generate Node Keys:${NC}"
    echo -e "   ./generate-node-keys.sh"
    echo ""
fi

if [ -d "nodes" ] && [ $(find nodes/Node*/geth/chaindata -type d 2>/dev/null | wc -l) -eq 0 ]; then
    echo -e "${YELLOW}3. Initialize Nodes:${NC}"
    echo -e "   ./initialize-nodes.sh"
    echo ""
fi

RUNNING=$(tmux ls 2>/dev/null | grep -c "node" || echo "0")
if [ "$RUNNING" -eq 0 ] && [ -d "nodes" ]; then
    echo -e "${YELLOW}4. Start Nodes:${NC}"
    echo -e "   ./start-all-nodes.sh"
    echo ""
fi

echo -e "${GREEN}For complete setup, run:${NC}"
echo -e "  ${CYAN}./setup-blockchain-complete.sh${NC}"
