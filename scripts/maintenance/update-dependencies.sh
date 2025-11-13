#!/bin/bash

# SilverBitcoin - Update Dependencies
# Updates Go modules and npm packages

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
echo -e "${CYAN}║   📦 SilverBitcoin - Update Dependencies                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check Go modules
echo -e "${YELLOW}1. Checking Go Modules (Geth)...${NC}"
echo ""

if [ -d "Blockchain/node_src" ]; then
    cd Blockchain/node_src
    
    if command -v go &> /dev/null; then
        echo -e "${CYAN}Current Go version:${NC}"
        go version
        echo ""
        
        echo -e "${CYAN}Checking for outdated modules...${NC}"
        go list -u -m all 2>/dev/null | grep '\[' | head -10 || echo -e "${GREEN}All modules up to date${NC}"
        echo ""
        
        read -p "Update Go modules? (yes/no): " update_go
        if [ "$update_go" = "yes" ] || [ "$update_go" = "y" ]; then
            echo -e "${YELLOW}Updating Go modules...${NC}"
            go get -u ./...
            go mod tidy
            echo -e "${GREEN}✓ Go modules updated${NC}"
        else
            echo -e "${YELLOW}Skipped Go modules update${NC}"
        fi
    else
        echo -e "${RED}✗ Go not found${NC}"
    fi
    
    cd ../..
else
    echo -e "${RED}✗ Blockchain/node_src not found${NC}"
fi

echo ""

# Check npm packages
echo -e "${YELLOW}2. Checking npm Packages (System Contracts)...${NC}"
echo ""

if [ -d "System-Contracts" ]; then
    cd System-Contracts
    
    if command -v npm &> /dev/null; then
        echo -e "${CYAN}Current Node/npm version:${NC}"
        node --version
        npm --version
        echo ""
        
        echo -e "${CYAN}Checking for outdated packages...${NC}"
        npm outdated || echo -e "${GREEN}All packages up to date${NC}"
        echo ""
        
        read -p "Update npm packages? (yes/no): " update_npm
        if [ "$update_npm" = "yes" ] || [ "$update_npm" = "y" ]; then
            echo -e "${YELLOW}Updating npm packages...${NC}"
            
            # Update to wanted versions (safe updates)
            npm update
            
            echo ""
            read -p "Update to latest versions? (may have breaking changes) (yes/no): " update_latest
            if [ "$update_latest" = "yes" ] || [ "$update_latest" = "y" ]; then
                echo -e "${YELLOW}Updating to latest versions...${NC}"
                npm update --latest
            fi
            
            echo -e "${GREEN}✓ npm packages updated${NC}"
            
            # Audit
            echo ""
            echo -e "${YELLOW}Running security audit...${NC}"
            npm audit || true
            
            read -p "Fix security vulnerabilities? (yes/no): " fix_audit
            if [ "$fix_audit" = "yes" ] || [ "$fix_audit" = "y" ]; then
                npm audit fix
            fi
        else
            echo -e "${YELLOW}Skipped npm packages update${NC}"
        fi
    else
        echo -e "${RED}✗ npm not found${NC}"
    fi
    
    cd ..
else
    echo -e "${RED}✗ System-Contracts not found${NC}"
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Dependency Check Complete                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Current Status:${NC}"
echo ""

# Go modules status
if [ -d "Blockchain/node_src" ] && command -v go &> /dev/null; then
    echo -e "${GREEN}Go Modules:${NC}"
    cd Blockchain/node_src
    echo "  Go version: $(go version | awk '{print $3}')"
    echo "  Module: $(grep '^module' go.mod | awk '{print $2}')"
    echo "  Go version required: $(grep '^go ' go.mod | awk '{print $2}')"
    cd ../..
fi

echo ""

# npm packages status
if [ -d "System-Contracts" ] && command -v npm &> /dev/null; then
    echo -e "${GREEN}npm Packages:${NC}"
    cd System-Contracts
    echo "  Node version: $(node --version)"
    echo "  npm version: $(npm --version)"
    echo "  Package: $(grep '"name"' package.json | head -1 | awk -F'"' '{print $4}')"
    echo "  Version: $(grep '"version"' package.json | head -1 | awk -F'"' '{print $4}')"
    cd ..
fi

echo ""
echo -e "${YELLOW}Notes:${NC}"
echo -e "  • Go modules are generally stable, update only if needed"
echo -e "  • npm packages can be updated more frequently"
echo -e "  • Always test after updates"
echo -e "  • Check for breaking changes in major version updates"
echo ""

echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. Test Geth build: ${YELLOW}cd Blockchain/node_src && go build -o geth ./cmd/geth${NC}"
echo -e "  2. Test contracts: ${YELLOW}cd System-Contracts && npm test${NC}"
