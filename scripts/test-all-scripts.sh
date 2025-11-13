#!/bin/bash

# Comprehensive test for all scripts

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🧪 Comprehensive Script Test                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

TOTAL=0
PASS=0
FAIL=0
SKIP=0

# Test function
test_script() {
    local script=$1
    local test_name=$2
    ((TOTAL++))
    
    echo -e "${YELLOW}Test $TOTAL: $test_name${NC}"
    
    # Check if script exists
    if [ ! -f "$script" ]; then
        echo -e "  ${RED}✗ FAIL - Script not found${NC}"
        ((FAIL++))
        return
    fi
    
    # Check if executable
    if [ ! -x "$script" ]; then
        echo -e "  ${YELLOW}⚠ Not executable, fixing...${NC}"
        chmod +x "$script"
    fi
    
    # Check syntax
    if bash -n "$script" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Syntax OK${NC}"
    else
        echo -e "  ${RED}✗ FAIL - Syntax error${NC}"
        ((FAIL++))
        return
    fi
    
    # Check for PROJECT_ROOT if needed
    if grep -q "cd \.\.\|^\./\|SilverBitcoin/\|Blockchain/" "$script" 2>/dev/null; then
        if grep -q "PROJECT_ROOT" "$script"; then
            echo -e "  ${GREEN}✓ Has PROJECT_ROOT${NC}"
        else
            echo -e "  ${YELLOW}⚠ May need PROJECT_ROOT${NC}"
        fi
    fi
    
    # Test path resolution
    local script_dir=$(dirname "$script")
    if grep -q "PROJECT_ROOT" "$script"; then
        if (cd "$script_dir" && bash -c '
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
            cd "$PROJECT_ROOT"
            [ -f "package.json" ]
        '); then
            echo -e "  ${GREEN}✓ Path resolution OK${NC}"
            ((PASS++))
        else
            echo -e "  ${RED}✗ FAIL - Path resolution failed${NC}"
            ((FAIL++))
            return
        fi
    else
        echo -e "  ${GREEN}✓ PASS (no path resolution needed)${NC}"
        ((PASS++))
    fi
}

echo -e "${CYAN}Testing Setup Scripts...${NC}"
test_script "scripts/setup/setup-blockchain-complete.sh" "setup-blockchain-complete.sh"
test_script "scripts/setup/generate-node-keys.sh" "generate-node-keys.sh"
test_script "scripts/setup/initialize-nodes.sh" "initialize-nodes.sh"
test_script "scripts/setup/setup-nodes.sh" "setup-nodes.sh"
echo ""

echo -e "${CYAN}Testing Node Management Scripts...${NC}"
test_script "scripts/node-management/start-all-nodes.sh" "start-all-nodes.sh"
test_script "scripts/node-management/start-node.sh" "start-node.sh"
test_script "scripts/node-management/stop-all-nodes.sh" "stop-all-nodes.sh"
test_script "scripts/node-management/stop-node.sh" "stop-node.sh"
test_script "scripts/node-management/node-status.sh" "node-status.sh"
echo ""

echo -e "${CYAN}Testing Maintenance Scripts...${NC}"
test_script "scripts/maintenance/troubleshoot.sh" "troubleshoot.sh"
test_script "scripts/maintenance/quick-test.sh" "quick-test.sh"
test_script "scripts/maintenance/update-dependencies.sh" "update-dependencies.sh"
test_script "scripts/maintenance/clean-build.sh" "clean-build.sh"
echo ""

echo -e "${CYAN}Testing Auto-Start Scripts...${NC}"
test_script "scripts/auto-start/setup-autostart-ubuntu.sh" "setup-autostart-ubuntu.sh"
test_script "scripts/auto-start/remove-autostart.sh" "remove-autostart.sh"
echo ""

echo -e "${CYAN}Testing Deployment Scripts...${NC}"
test_script "scripts/deployment/cleanup-for-github.sh" "cleanup-for-github.sh"
test_script "scripts/deployment/prepare-for-github.sh" "prepare-for-github.sh"
test_script "scripts/deployment/create-release.sh" "create-release.sh"
echo ""

echo -e "${CYAN}Testing Utility Scripts...${NC}"
test_script "scripts/utilities/generate-address.sh" "generate-address.sh"
test_script "scripts/utilities/join-existing-network.sh" "join-existing-network.sh"
echo ""

# Summary
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📊 Test Summary                                          ║${NC}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║   Total:  $TOTAL                                              ║${NC}"
echo -e "${CYAN}║   ${GREEN}Passed: $PASS${CYAN}                                              ║${NC}"
echo -e "${CYAN}║   ${RED}Failed: $FAIL${CYAN}                                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Scripts are ready to use.${NC}"
    echo ""
    echo -e "${YELLOW}Quick Start:${NC}"
    echo -e "  Setup:  ${CYAN}scripts/setup/setup-blockchain-complete.sh${NC}"
    echo -e "  Start:  ${CYAN}scripts/node-management/start-all-nodes.sh${NC}"
    echo -e "  Status: ${CYAN}scripts/node-management/node-status.sh${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the errors above.${NC}"
    exit 1
fi
