#!/bin/bash

# Quick test script for Ubuntu 24.04 compatibility

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
echo -e "${CYAN}║   🧪 SilverBitcoin Quick Test (Ubuntu 24.04)              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

PASS=0
FAIL=0

# Test 1: Check OS
echo -e "${YELLOW}Test 1: Checking OS...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$VERSION_ID" == "24.04" ]]; then
        echo -e "  ${GREEN}✓ Ubuntu 24.04 detected${NC}"
        ((PASS++))
    else
        echo -e "  ${YELLOW}⚠ OS: $NAME $VERSION_ID (not 24.04)${NC}"
        ((PASS++))
    fi
else
    echo -e "  ${RED}✗ Cannot detect OS${NC}"
    ((FAIL++))
fi

# Test 2: Check Go
echo -e "${YELLOW}Test 2: Checking Go...${NC}"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    echo -e "  ${GREEN}✓ Go $GO_VERSION installed${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ Go not found${NC}"
    ((FAIL++))
fi

# Test 3: Check tmux
echo -e "${YELLOW}Test 3: Checking tmux...${NC}"
if command -v tmux &> /dev/null; then
    echo -e "  ${GREEN}✓ tmux installed${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ tmux not found${NC}"
    ((FAIL++))
fi

# Test 4: Check Python3
echo -e "${YELLOW}Test 4: Checking Python3...${NC}"
if command -v python3 &> /dev/null; then
    echo -e "  ${GREEN}✓ Python3 installed${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ Python3 not found${NC}"
    ((FAIL++))
fi

# Test 5: Check build tools
echo -e "${YELLOW}Test 5: Checking build tools...${NC}"
if command -v gcc &> /dev/null && command -v make &> /dev/null; then
    echo -e "  ${GREEN}✓ Build tools installed${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ Build tools missing${NC}"
    ((FAIL++))
fi

# Test 6: Check scripts
echo -e "${YELLOW}Test 6: Checking scripts...${NC}"
REQUIRED_SCRIPTS="setup-blockchain-complete.sh start-all-nodes.sh stop-all-nodes.sh generate-node-keys.sh initialize-nodes.sh start-node.sh"
MISSING_SCRIPTS=""
for script in $REQUIRED_SCRIPTS; do
    if [ ! -f "$script" ]; then
        MISSING_SCRIPTS="$MISSING_SCRIPTS $script"
    fi
done

if [ -z "$MISSING_SCRIPTS" ]; then
    echo -e "  ${GREEN}✓ All required scripts found${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ Missing scripts:$MISSING_SCRIPTS${NC}"
    ((FAIL++))
fi

# Test 7: Check Geth source
echo -e "${YELLOW}Test 7: Checking Geth source...${NC}"
if [ -d "Blockchain/node_src" ]; then
    echo -e "  ${GREEN}✓ Geth source found${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ Geth source not found${NC}"
    ((FAIL++))
fi

# Test 8: Check Genesis
echo -e "${YELLOW}Test 8: Checking Genesis...${NC}"
if [ -f "genesis.json" ] || [ -f "Blockchain/genesis.json" ]; then
    echo -e "  ${GREEN}✓ Genesis.json found${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ Genesis.json not found${NC}"
    ((FAIL++))
fi

# Test 9: Test tmux functionality
echo -e "${YELLOW}Test 9: Testing tmux...${NC}"
if command -v tmux &> /dev/null; then
    # Create a test session
    tmux new-session -d -s "silverbitcoin-test" "echo 'test' && sleep 1" 2>/dev/null
    sleep 1
    if tmux has-session -t "silverbitcoin-test" 2>/dev/null; then
        tmux kill-session -t "silverbitcoin-test" 2>/dev/null
        echo -e "  ${GREEN}✓ tmux working correctly${NC}"
        ((PASS++))
    else
        echo -e "  ${YELLOW}⚠ tmux session test inconclusive${NC}"
        ((PASS++))
    fi
else
    echo -e "  ${RED}✗ Cannot test tmux${NC}"
    ((FAIL++))
fi

# Test 10: Check disk space
echo -e "${YELLOW}Test 10: Checking disk space...${NC}"
AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE" -gt 20 ]; then
    echo -e "  ${GREEN}✓ Sufficient disk space (${AVAILABLE}GB available)${NC}"
    ((PASS++))
else
    echo -e "  ${YELLOW}⚠ Low disk space (${AVAILABLE}GB available, 20GB+ recommended)${NC}"
    ((PASS++))
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📊 Test Results                                          ║${NC}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║   ${GREEN}Passed: $PASS${CYAN}                                              ║${NC}"
echo -e "${CYAN}║   ${RED}Failed: $FAIL${CYAN}                                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! System is ready.${NC}"
    echo ""
    echo -e "${YELLOW}Next step:${NC}"
    echo -e "  ${CYAN}./setup-blockchain-complete.sh${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix the issues above.${NC}"
    echo ""
    echo -e "${YELLOW}For detailed diagnostics, run:${NC}"
    echo -e "  ${CYAN}./troubleshoot.sh${NC}"
    exit 1
fi
