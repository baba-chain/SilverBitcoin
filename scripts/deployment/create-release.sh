#!/bin/bash

# SilverBitcoin Release Creator
# Creates a distributable package for deployment

set -e

# Get the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

VERSION=${1:-"1.0.0"}
RELEASE_NAME="silverbitcoin-v${VERSION}"
RELEASE_DIR="releases/${RELEASE_NAME}"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📦 Creating SilverBitcoin Release Package               ║${NC}"
echo -e "${CYAN}║   Version: ${VERSION}                                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Clean old releases
if [ -d "$RELEASE_DIR" ]; then
    echo -e "${ORANGE}Removing old release directory...${NC}"
    rm -rf "$RELEASE_DIR"
fi

mkdir -p "$RELEASE_DIR"

echo -e "\n${CYAN}[1/6] Copying core files...${NC}"

# Copy essential files
cp -r SilverBitcoin "$RELEASE_DIR/"
cp -r nodes "$RELEASE_DIR/"
cp -r validator-dashboard "$RELEASE_DIR/"
cp -r deployment "$RELEASE_DIR/"

# Copy scripts
cp start-node.sh "$RELEASE_DIR/"
cp start-all-nodes.sh "$RELEASE_DIR/"
cp stop-node.sh "$RELEASE_DIR/"
cp stop-all-nodes.sh "$RELEASE_DIR/"
cp node-status.sh "$RELEASE_DIR/"

# Copy documentation
cp README.md "$RELEASE_DIR/" 2>/dev/null || true
cp NODE-MANAGEMENT.md "$RELEASE_DIR/"
cp NODE-STRUCTURE.md "$RELEASE_DIR/"
cp DEPLOYMENT-SUMMARY.md "$RELEASE_DIR/"
cp SYNC-HELPER-SETUP.md "$RELEASE_DIR/"

echo -e "${GREEN}✓ Core files copied${NC}"

echo -e "\n${CYAN}[2/6] Cleaning up...${NC}"

# Remove unnecessary files
find "$RELEASE_DIR" -name ".DS_Store" -delete
find "$RELEASE_DIR" -name "*.log" -delete
find "$RELEASE_DIR" -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
find "$RELEASE_DIR" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove blockchain data (users will initialize fresh)
rm -rf "$RELEASE_DIR/nodes/*/geth" 2>/dev/null || true
rm -rf "$RELEASE_DIR/nodes/*/keystore" 2>/dev/null || true

echo -e "${GREEN}✓ Cleanup complete${NC}"

echo -e "\n${CYAN}[3/6] Creating version info...${NC}"

cat > "$RELEASE_DIR/VERSION" << EOF
SilverBitcoin Version: ${VERSION}
Release Date: $(date +"%Y-%m-%d %H:%M:%S")
Chain ID: 5200
Network ID: 5200
Total Nodes: 25 (24 validators + 1 treasury)
Consensus: Proof of Authority (PoA)
Block Time: 1 second
EOF

echo -e "${GREEN}✓ Version info created${NC}"

echo -e "\n${CYAN}[4/6] Creating installation guide...${NC}"

cat > "$RELEASE_DIR/INSTALL.txt" << 'EOF'
╔════════════════════════════════════════════════════════════╗
║        SilverBitcoin Installation Quick Start             ║
╚════════════════════════════════════════════════════════════╝

LINUX (Ubuntu):
1. Extract this archive to /opt/silverbitcoin
2. Run: sudo ./deployment/linux/install.sh
3. Build Geth: cd Blockchain/node_src && make geth
4. Start nodes: ./start-all-nodes.sh
5. Start dashboard: cd validator-dashboard && npm install && npm start

WINDOWS:
1. Extract this archive to C:\SilverBitcoin
2. Run as Admin: .\deployment\windows\install.ps1
3. Build Geth: cd SilverBitcoin\node_src && go build -o ..\build\bin\geth.exe ./cmd/geth
4. Start nodes: .\start-all-nodes.bat
5. Start dashboard: cd validator-dashboard && npm install && npm start

DOCUMENTATION:
- Full guide: DEPLOYMENT-SUMMARY.md
- Node management: NODE-MANAGEMENT.md
- Network structure: NODE-STRUCTURE.md

SUPPORT:
- Check logs first
- Review troubleshooting in documentation
- Visit GitHub issues

SECURITY:
⚠️  IMPORTANT: Backup all private_key.txt files!
⚠️  Never share private keys
⚠️  Configure firewall properly
EOF

echo -e "${GREEN}✓ Installation guide created${NC}"

echo -e "\n${CYAN}[5/6] Creating checksums...${NC}"

cd "$RELEASE_DIR"
find . -type f -exec sha256sum {} \; > CHECKSUMS.txt
cd - > /dev/null

echo -e "${GREEN}✓ Checksums created${NC}"

echo -e "\n${CYAN}[6/6] Creating archive...${NC}"

cd releases
tar -czf "${RELEASE_NAME}.tar.gz" "${RELEASE_NAME}"
zip -r -q "${RELEASE_NAME}.zip" "${RELEASE_NAME}"
cd - > /dev/null

# Calculate sizes
TAR_SIZE=$(du -h "releases/${RELEASE_NAME}.tar.gz" | cut -f1)
ZIP_SIZE=$(du -h "releases/${RELEASE_NAME}.zip" | cut -f1)

echo -e "${GREEN}✓ Archives created${NC}"

# Summary
echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Release Package Created Successfully!                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Release Information:${NC}"
echo -e "  Version:     ${CYAN}${VERSION}${NC}"
echo -e "  Directory:   ${CYAN}${RELEASE_DIR}${NC}"
echo -e "  TAR.GZ:      ${CYAN}releases/${RELEASE_NAME}.tar.gz${NC} (${TAR_SIZE})"
echo -e "  ZIP:         ${CYAN}releases/${RELEASE_NAME}.zip${NC} (${ZIP_SIZE})"

echo -e "\n${GREEN}Contents:${NC}"
echo -e "  ✓ SilverBitcoin source code"
echo -e "  ✓ 25 pre-configured nodes"
echo -e "  ✓ Validator dashboard"
echo -e "  ✓ Deployment scripts (Linux & Windows)"
echo -e "  ✓ Management scripts"
echo -e "  ✓ Complete documentation"

echo -e "\n${GREEN}Next Steps:${NC}"
echo -e "  ${ORANGE}1.${NC} Test the release package"
echo -e "  ${ORANGE}2.${NC} Upload to GitHub releases"
echo -e "  ${ORANGE}3.${NC} Update installation scripts with correct URLs"
echo -e "  ${ORANGE}4.${NC} Announce the release"

echo -e "\n${CYAN}GitHub Release Command:${NC}"
echo -e "  ${ORANGE}gh release create v${VERSION} \\${NC}"
echo -e "    ${ORANGE}releases/${RELEASE_NAME}.tar.gz \\${NC}"
echo -e "    ${ORANGE}releases/${RELEASE_NAME}.zip \\${NC}"
echo -e "    ${ORANGE}--title \"SilverBitcoin v${VERSION}\" \\${NC}"
echo -e "    ${ORANGE}--notes \"Release notes here\"${NC}"

echo -e "\n${GREEN}✓ Release creation complete!${NC}"
