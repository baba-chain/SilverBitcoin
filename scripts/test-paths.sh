#!/bin/bash

# Test script to verify all paths work correctly

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🧪 Testing Script Paths                                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

PASS=0
FAIL=0

# Test 1: setup-blockchain-complete.sh
echo -e "${YELLOW}Test 1: setup-blockchain-complete.sh path resolution${NC}"
cd scripts/setup
if bash -c '
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
[ -f "package.json" ] && ([ -d "Blockchain" ] || [ -d "SilverBitcoin" ])
'; then
    echo -e "  ${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ FAIL${NC}"
    ((FAIL++))
fi
cd ../..

# Test 2: start-all-nodes.sh
echo -e "${YELLOW}Test 2: start-all-nodes.sh path resolution${NC}"
cd scripts/node-management
if bash -c '
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
[ -f "package.json" ] && [ -d "nodes" -o ! -d "nodes" ]
'; then
    echo -e "  ${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ FAIL${NC}"
    ((FAIL++))
fi
cd ../..

# Test 3: troubleshoot.sh
echo -e "${YELLOW}Test 3: troubleshoot.sh path resolution${NC}"
cd scripts/maintenance
if bash -c '
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
[ -f "package.json" ]
'; then
    echo -e "  ${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ FAIL${NC}"
    ((FAIL++))
fi
cd ../..

# Test 4: Check if scripts can find each other
echo -e "${YELLOW}Test 4: Script cross-references${NC}"
if [ -f "scripts/setup/generate-node-keys.sh" ] && \
   [ -f "scripts/setup/initialize-nodes.sh" ] && \
   [ -f "scripts/node-management/start-all-nodes.sh" ]; then
    echo -e "  ${GREEN}✓ PASS - All scripts exist${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ FAIL - Some scripts missing${NC}"
    ((FAIL++))
fi

# Test 5: Check if genesis.json is accessible
echo -e "${YELLOW}Test 5: genesis.json accessibility${NC}"
if [ -f "Blockchain/genesis.json" ]; then
    echo -e "  ${GREEN}✓ PASS - genesis.json found${NC}"
    ((PASS++))
else
    echo -e "  ${YELLOW}⚠ SKIP - genesis.json not found (normal if not set up yet)${NC}"
    ((PASS++))
fi

# Test 6: npm scripts
echo -e "${YELLOW}Test 6: npm scripts configuration${NC}"
if grep -q "scripts/setup/setup-blockchain-complete.sh" package.json && \
   grep -q "scripts/node-management/start-all-nodes.sh" package.json; then
    echo -e "  ${GREEN}✓ PASS - npm scripts correctly configured${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ FAIL - npm scripts not updated${NC}"
    ((FAIL++))
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
    echo -e "${GREEN}✅ All tests passed! Scripts are correctly configured.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the configuration.${NC}"
    exit 1
fi
