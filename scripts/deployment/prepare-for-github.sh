#!/bin/bash

# SilverBitcoin - Complete GitHub Preparation Script
# Cleans everything and prepares for GitHub upload

set -e

# Get the project root directory
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
echo -e "${CYAN}║   🚀 SilverBitcoin - GitHub Preparation                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo -e "  1. Clean build artifacts (node_modules, binaries, etc.)"
echo -e "  2. Update copyright notices"
echo -e "  3. Remove go-ethereum license blocks"
echo -e "  4. Remove unnecessary files"
echo ""
echo -e "${RED}⚠️  This will modify many files!${NC}"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
    echo -e "${RED}❌ Cancelled.${NC}"
    exit 0
fi

echo ""

# Step 1: Clean build artifacts
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 1/4: Cleaning Build Artifacts                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "clean-build.sh" ]; then
    ./clean-build.sh
else
    echo -e "${YELLOW}⚠️  clean-build.sh not found, skipping...${NC}"
fi

echo ""

# Step 2: Update copyright
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 2/4: Updating Copyright                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "update-copyright-advanced.py" ]; then
    python3 update-copyright-advanced.py
else
    echo -e "${YELLOW}⚠️  update-copyright-advanced.py not found, skipping...${NC}"
fi

echo ""

# Step 3: Remove license blocks
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 3/4: Removing License Blocks                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "remove-geth-license-advanced.py" ]; then
    python3 remove-geth-license-advanced.py
else
    echo -e "${YELLOW}⚠️  remove-geth-license-advanced.py not found, skipping...${NC}"
fi

echo ""

# Step 4: Clean unnecessary files
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 4/4: Cleaning Unnecessary Files                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "cleanup-for-github.sh" ]; then
    ./cleanup-for-github.sh
else
    echo -e "${YELLOW}⚠️  cleanup-for-github.sh not found, skipping...${NC}"
fi

echo ""

# Final summary
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Preparation Complete!                                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show repository size
REPO_SIZE=$(du -sh . 2>/dev/null | cut -f1)
echo -e "${GREEN}Repository size: $REPO_SIZE${NC}"
echo ""

# Show git status
echo -e "${YELLOW}Git status:${NC}"
git status --short | head -20
echo ""

# Next steps
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📋 Next Steps                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}1. Review changes:${NC}"
echo -e "   ${CYAN}git status${NC}"
echo -e "   ${CYAN}git diff${NC}"
echo ""
echo -e "${YELLOW}2. Push to GitHub:${NC}"
echo -e "   ${CYAN}./push-to-github.sh${NC}"
echo ""
echo -e "${GREEN}🚀 Ready for GitHub!${NC}"
