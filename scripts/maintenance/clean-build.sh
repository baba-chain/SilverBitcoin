#!/bin/bash

# SilverBitcoin - Quick Build Cleanup Script
# Removes build artifacts and dependencies

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🧹 SilverBitcoin - Quick Build Cleanup                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to get directory size
get_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# Function to remove directory
remove_dir() {
    if [ -d "$1" ]; then
        SIZE=$(get_size "$1")
        rm -rf "$1"
        echo -e "${GREEN}✅ Removed: $1 ($SIZE)${NC}"
        return 0
    fi
    return 1
}

# Function to remove file
remove_file() {
    if [ -f "$1" ]; then
        SIZE=$(ls -lh "$1" 2>/dev/null | awk '{print $5}')
        rm -f "$1"
        echo -e "${GREEN}✅ Removed: $1 ($SIZE)${NC}"
        return 0
    fi
    return 1
}

echo -e "${YELLOW}Cleaning Node.js artifacts...${NC}"
find . -name "node_modules" -type d -prune -exec rm -rf {} + 2>/dev/null || true
find . -name "package-lock.json" -type f -delete 2>/dev/null || true
find . -name "yarn.lock" -type f -delete 2>/dev/null || true
echo ""

echo -e "${YELLOW}Cleaning Go artifacts...${NC}"
# Remove compiled binaries
remove_file "geth"
remove_file "geth.exe"
remove_file "bootnode"
remove_file "evm"
remove_file "clef"

# Clean Go cache
if command -v go &> /dev/null; then
    echo -e "${CYAN}Running go clean...${NC}"
    go clean -cache -modcache 2>/dev/null || true
    echo -e "${GREEN}✅ Go cache cleaned${NC}"
fi

# Remove vendor directories
find . -name "vendor" -type d -prune -exec rm -rf {} + 2>/dev/null || true
echo ""

echo -e "${YELLOW}Cleaning build directories...${NC}"
remove_dir "build"
remove_dir "dist"
remove_dir "out"
remove_dir "bin"
echo ""

echo -e "${YELLOW}Cleaning Python artifacts...${NC}"
find . -name "__pycache__" -type d -prune -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -type f -delete 2>/dev/null || true
find . -name ".pytest_cache" -type d -prune -exec rm -rf {} + 2>/dev/null || true
echo ""

echo -e "${YELLOW}Cleaning IDE files...${NC}"
remove_dir ".vscode"
remove_dir ".idea"
remove_dir ".kiro"
echo ""

echo -e "${YELLOW}Cleaning OS files...${NC}"
find . -name ".DS_Store" -type f -delete 2>/dev/null || true
find . -name "Thumbs.db" -type f -delete 2>/dev/null || true
find . -name "desktop.ini" -type f -delete 2>/dev/null || true
echo ""

echo -e "${YELLOW}Cleaning temporary files...${NC}"
find . -name "*.log" -type f -delete 2>/dev/null || true
find . -name "*.tmp" -type f -delete 2>/dev/null || true
find . -name "*.swp" -type f -delete 2>/dev/null || true
find . -name "*~" -type f -delete 2>/dev/null || true
remove_dir "tmp"
remove_dir "temp"
remove_dir ".cache"
echo ""

echo -e "${YELLOW}Cleaning backup directories...${NC}"
find . -name "backup-*" -type d -prune -exec rm -rf {} + 2>/dev/null || true
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Cleanup Complete!                                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Repository is now clean and ready for GitHub!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Check size: ${CYAN}du -sh .${NC}"
echo -e "  2. Check git: ${CYAN}git status${NC}"
echo -e "  3. Push to GitHub: ${CYAN}./push-to-github.sh${NC}"
