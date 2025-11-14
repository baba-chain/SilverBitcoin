#!/bin/bash

################################################################################
# SilverBitcoin - Complete Blockchain Setup Script
################################################################################
#
# DESCRIPTION:
#   This script provides a complete, automated setup for the SilverBitcoin
#   blockchain network. It handles all aspects of deployment including:
#   - System dependency installation
#   - Go version management (automatic detection and installation)
#   - Geth compilation from source
#   - Validator key generation
#   - Genesis block initialization
#   - Node startup and configuration
#
# COMPATIBILITY:
#   - Ubuntu 22.04 LTS (Jammy Jellyfish)
#   - Ubuntu 24.04 LTS (Noble Numbat)
#   - Ubuntu 25.10 (Oracular Oriole)
#
# GO VERSION REQUIREMENTS:
#   This script requires Go 1.21 or 1.22 for Geth compilation.
#   Go 1.23+ is NOT compatible due to breaking changes in the runtime package.
#
#   Technical Details:
#   - Go 1.23+ removed/changed the runtime.stopTheWorld API
#   - The dependency github.com/fjl/memsize (used by go-ethereum) relies on
#     internal runtime APIs that changed in Go 1.23
#   - This causes compilation errors: "invalid reference to runtime.stopTheWorld"
#
#   Automatic Go Management:
#   - The script automatically detects your current Go version
#   - If incompatible (1.23+) or missing, it installs Go 1.22
#   - Multiple Go versions can coexist using update-alternatives
#   - The correct version is automatically selected for the build
#
# USAGE:
#   ./setup-blockchain-complete.sh
#
#   The script will:
#   1. Check and install system dependencies
#   2. Detect and validate Go installation
#   3. Install compatible Go version if needed
#   4. Build Geth binary from source
#   5. Generate validator private keys (25 nodes)
#   6. Update genesis.json with validator addresses
#   7. Initialize genesis block for all nodes
#   8. Start all validator nodes in tmux sessions
#
# PREREQUISITES:
#   - Ubuntu 22.04, 24.04, or 25.10
#   - Sudo privileges (for package installation)
#   - Internet connection (for downloading Go and modules)
#   - At least 2GB free disk space
#   - At least 2GB RAM
#
# SECURITY NOTES:
#   - This script generates private keys for validator nodes
#   - Keys are stored in nodes/Node*/keystore/
#   - NEVER commit these keys to version control
#   - The .gitignore file protects these directories
#   - Run this script ONLY on the server, not on development machines
#
# TROUBLESHOOTING:
#   If the script fails:
#   1. Check the error message - it provides specific guidance
#   2. Verify internet connectivity
#   3. Ensure sufficient disk space: df -h
#   4. Check Go version: go version
#   5. Review logs in the output above
#
#   Common Issues:
#   - "runtime.stopTheWorld" error: Go 1.23+ detected, script will auto-fix
#   - Module download failures: Check network/proxy settings
#   - Permission denied: Run with sudo or fix directory permissions
#   - Disk space errors: Free up space and retry
#
# SUPPORT:
#   - Documentation: See README.md
#   - Issues: GitHub Issues
#   - Community: GitHub Discussions
#
################################################################################

# Note: We don't use 'set -e' globally because we need to handle errors gracefully
# and continue with automatic fixes. Critical errors are handled explicitly.

# Get the project root directory (2 levels up from scripts/setup/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load Go version manager module
# This provides complete Go detection, validation, and installation functionality
GO_VERSION_MANAGER="$SCRIPT_DIR/go-version-manager.sh"
if [ -f "$GO_VERSION_MANAGER" ]; then
    source "$GO_VERSION_MANAGER"
    echo -e "${GREEN}✓ Go version manager loaded${NC}"
else
    echo -e "${RED}✗ Go version manager not found: $GO_VERSION_MANAGER${NC}"
    echo -e "${YELLOW}Please ensure go-version-manager.sh exists in scripts/setup/${NC}"
    exit 1
fi

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 SilverBitcoin - Complete Blockchain Setup            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo -e "  0. Check and install system dependencies"
echo -e "  1. Build Geth binary"
echo -e "  2. Generate validator private keys"
echo -e "  3. Update genesis.json with new addresses"
echo -e "  4. Initialize genesis for all nodes"
echo -e "  5. Start all validator nodes"
echo ""
echo -e "${RED}⚠️  This should be run ONLY on the server!${NC}"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
    echo -e "${RED}❌ Cancelled.${NC}"
    exit 0
fi

echo ""

# Step 0: Check and Install Dependencies
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 0/6: Checking System Dependencies                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
    echo -e "${YELLOW}Running with sudo...${NC}"
else
    SUDO=""
    echo -e "${YELLOW}Running as root...${NC}"
fi

#######################################
# GO VERSION DETECTION AND MANAGEMENT
# This section uses the go-version-manager module to:
# 1. Detect current Go installation
# 2. Validate compatibility (requires Go 1.21 or 1.22)
# 3. Automatically install compatible version if needed
# 4. Configure system PATH for Go access
#######################################

echo -e "${CYAN}Checking Go installation and compatibility...${NC}"
echo ""

echo -e "${YELLOW}[DEBUG] About to call check_go_version_complete...${NC}"

# Perform complete Go version check
# Returns: 0 = compatible, 1 = not found, 2 = incompatible
check_go_version_complete
GO_CHECK_RESULT=$?

echo -e "${YELLOW}[DEBUG] check_go_version_complete returned${NC}"
echo ""
echo -e "${CYAN}[DEBUG] Go check result code: $GO_CHECK_RESULT${NC}"
echo ""

# Handle different scenarios based on check result
case $GO_CHECK_RESULT in
    0)
        # Go is installed and compatible - proceed with build
        echo -e "${GREEN}✅ Go is ready for Geth compilation${NC}"
        echo ""
        ;;
    1)
        # Go is not installed - install it
        echo -e "${YELLOW}⚠️  Go is not installed${NC}"
        echo -e "${CYAN}Installing compatible Go version...${NC}"
        echo ""
        
        if install_compatible_go "$SUDO"; then
            echo ""
            echo -e "${GREEN}✅ Go installed successfully${NC}"
            
            # Configure system PATH
            if [ -n "$GO_INSTALL_PATH" ]; then
                echo ""
                if configure_go_system_path "$GO_INSTALL_PATH" "$SUDO"; then
                    echo -e "${GREEN}✅ Go configured in system PATH${NC}"
                else
                    echo -e "${YELLOW}⚠️  Manual PATH configuration may be needed${NC}"
                fi
            fi
            
            # Re-check to confirm installation
            echo ""
            echo -e "${CYAN}Verifying installation...${NC}"
            if check_go_version_complete; then
                echo -e "${GREEN}✅ Go installation verified${NC}"
            else
                echo -e "${RED}✗ Go installation verification failed${NC}"
                exit 1
            fi
        else
            echo ""
            echo -e "${RED}✗ Failed to install Go${NC}"
            echo -e "${YELLOW}Please install Go manually and re-run this script${NC}"
            exit 1
        fi
        echo ""
        ;;
    2)
        # Go is installed but incompatible version - COMPLETE CLEAN REINSTALL
        echo -e "${YELLOW}⚠️  Incompatible Go version detected${NC}"
        echo -e "${CYAN}Current version: ${GO_VERSION_FULL}${NC}"
        echo -e "${CYAN}Required: Go 1.21 or 1.22${NC}"
        echo ""
        echo -e "${YELLOW}Technical Issue:${NC}"
        echo -e "  Go 1.23+ has breaking changes in runtime package"
        echo -e "  The runtime.stopTheWorld API affects github.com/fjl/memsize"
        echo -e "  This prevents Geth compilation"
        echo ""
        echo -e "${CYAN}Automatic Solution:${NC}"
        echo -e "  1. Complete removal of incompatible Go ${GO_VERSION_FULL}"
        echo -e "  2. Installation of all required build dependencies"
        echo -e "  3. Clean installation of compatible Go 1.22"
        echo -e "  4. System configuration for Geth build"
        echo ""
        echo -e "${YELLOW}Starting automatic fix...${NC}"
        echo ""
        
        # Step 1: Complete Go uninstallation
        echo -e "${CYAN}═══ Phase 1: Removing Incompatible Go ═══${NC}"
        if uninstall_go_completely "$SUDO"; then
            echo -e "${GREEN}✅ Incompatible Go removed completely${NC}"
        else
            echo -e "${YELLOW}⚠ Uninstall completed with warnings${NC}"
        fi
        echo ""
        
        # Step 2: Install all build dependencies
        echo -e "${CYAN}═══ Phase 2: Installing Build Dependencies ═══${NC}"
        if install_all_build_dependencies "$SUDO"; then
            echo -e "${GREEN}✅ All build dependencies installed${NC}"
        else
            echo -e "${YELLOW}⚠ Some dependencies may have failed${NC}"
        fi
        echo ""
        
        # Step 3: Install compatible Go
        echo -e "${CYAN}═══ Phase 3: Installing Compatible Go 1.22 ═══${NC}"
        if install_compatible_go "$SUDO"; then
            echo -e "${GREEN}✅ Go 1.22 installed successfully${NC}"
            
            # Configure system PATH
            if [ -n "$GO_INSTALL_PATH" ]; then
                echo ""
                if configure_go_system_path "$GO_INSTALL_PATH" "$SUDO"; then
                    echo -e "${GREEN}✅ Go configured in system PATH${NC}"
                else
                    echo -e "${YELLOW}⚠️  Manual PATH configuration may be needed${NC}"
                fi
            fi
        else
            echo ""
            echo -e "${RED}✗ Failed to install compatible Go${NC}"
            echo -e "${YELLOW}Please install Go 1.21 or 1.22 manually and re-run this script${NC}"
            exit 1
        fi
        echo ""
        
        # Step 4: Final verification
        echo -e "${CYAN}═══ Phase 4: Verification ═══${NC}"
        if check_go_version_complete; then
            echo ""
            echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║   ✅ System Ready for Geth Compilation                    ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "${GREEN}Summary:${NC}"
            echo -e "${GREEN}  ✓ Incompatible Go removed${NC}"
            echo -e "${GREEN}  ✓ All dependencies installed${NC}"
            echo -e "${GREEN}  ✓ Go 1.22 installed and configured${NC}"
            echo -e "${GREEN}  ✓ System verified and ready${NC}"
            echo ""
        else
            echo -e "${RED}✗ Verification failed${NC}"
            echo -e "${YELLOW}Please check the errors above${NC}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}✗ Unexpected error during Go version check${NC}"
        exit 1
        ;;
esac

# Check other dependencies
PACKAGES="git build-essential tmux curl wget openssl libgmp-dev libssl-dev pkg-config python3"
MISSING_PACKAGES=""

echo -e "${YELLOW}Checking dependencies...${NC}"
for pkg in $PACKAGES; do
    if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
        MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
    fi
done

if [ ! -z "$MISSING_PACKAGES" ]; then
    echo -e "${YELLOW}Installing missing packages:$MISSING_PACKAGES${NC}"
    $SUDO apt update -qq
    $SUDO apt install -y $MISSING_PACKAGES
    echo -e "${GREEN}✓ Packages installed${NC}"
else
    echo -e "${GREEN}✓ All required packages installed${NC}"
fi

# Copy genesis.json if not exists
if [ ! -f "genesis.json" ]; then
    if [ -f "Blockchain/genesis.json" ]; then
        echo -e "${YELLOW}Copying genesis.json from Blockchain/...${NC}"
        cp Blockchain/genesis.json .
        echo -e "${GREEN}✓ Genesis.json copied${NC}"
    elif [ -f "SilverBitcoin/genesis.json" ]; then
        echo -e "${YELLOW}Copying genesis.json from SilverBitcoin/...${NC}"
        cp SilverBitcoin/genesis.json .
        echo -e "${GREEN}✓ Genesis.json copied${NC}"
    fi
fi

echo ""

# Step 1: Build Geth
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 1/6: Building Geth                                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "geth" ]; then
    # Try both Blockchain and SilverBitcoin directories
    GETH_SRC_DIR=""
    if [ -d "Blockchain/node_src" ]; then
        GETH_SRC_DIR="Blockchain/node_src"
    elif [ -d "SilverBitcoin/node_src" ]; then
        GETH_SRC_DIR="SilverBitcoin/node_src"
    fi
    
    if [ -n "$GETH_SRC_DIR" ]; then
        echo -e "${YELLOW}Building Geth from source ($GETH_SRC_DIR)...${NC}"
        
        #######################################
        # CONFIGURE BUILD ENVIRONMENT
        # Set up Go environment variables to ensure correct Go version is used
        # This is critical for Ubuntu 25.10 where system Go might be 1.23+
        #######################################
        
        echo ""
        echo -e "${CYAN}Configuring build environment...${NC}"
        
        # Determine which Go binary to use
        # Priority: 1. GO_BINARY_PATH from version check, 2. System go command
        BUILD_GO_BINARY=""
        if [ -n "$GO_BINARY_PATH" ] && [ -x "$GO_BINARY_PATH" ]; then
            BUILD_GO_BINARY="$GO_BINARY_PATH"
            echo -e "${GREEN}✓ Using Go from: $BUILD_GO_BINARY${NC}"
        elif command -v go &>/dev/null; then
            BUILD_GO_BINARY=$(command -v go)
            echo -e "${GREEN}✓ Using system Go: $BUILD_GO_BINARY${NC}"
        else
            echo -e "${RED}✗ No Go binary found${NC}"
            echo -e "${YELLOW}This should not happen after Go installation${NC}"
            exit 1
        fi
        
        # Get GOROOT from the Go binary
        BUILD_GOROOT=$($BUILD_GO_BINARY env GOROOT 2>/dev/null)
        if [ -z "$BUILD_GOROOT" ]; then
            # Fallback: derive GOROOT from binary path
            BUILD_GOROOT=$(dirname $(dirname "$BUILD_GO_BINARY"))
            echo -e "${YELLOW}⚠ GOROOT derived from binary path: $BUILD_GOROOT${NC}"
        else
            echo -e "${GREEN}✓ GOROOT: $BUILD_GOROOT${NC}"
        fi
        
        # Validate GOROOT exists
        if [ ! -d "$BUILD_GOROOT" ]; then
            echo -e "${RED}✗ GOROOT directory does not exist: $BUILD_GOROOT${NC}"
            exit 1
        fi
        
        # Set up Go environment variables
        # These ensure the build uses the correct Go version
        export GOROOT="$BUILD_GOROOT"
        export GOPATH="${HOME}/go"
        export GO111MODULE=on
        export CGO_ENABLED=1
        
        # Construct PATH with Go binary directory first
        # This ensures our compatible Go version takes precedence
        GO_BIN_DIR="$BUILD_GOROOT/bin"
        if [ -d "$GO_BIN_DIR" ]; then
            # Remove any existing Go paths to prevent conflicts
            PATH_WITHOUT_GO=$(echo "$PATH" | tr ':' '\n' | grep -v '/go' | tr '\n' ':' | sed 's/:$//')
            export PATH="$GO_BIN_DIR:$PATH_WITHOUT_GO"
            echo -e "${GREEN}✓ PATH configured with Go binary directory first${NC}"
        else
            echo -e "${YELLOW}⚠ Go bin directory not found: $GO_BIN_DIR${NC}"
        fi
        
        # Verify the environment configuration
        echo ""
        echo -e "${CYAN}Verifying build environment...${NC}"
        
        # Check which go binary will be used
        ACTIVE_GO=$(command -v go)
        ACTIVE_GO_VERSION=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 | sed 's/^go//')
        
        if [ "$ACTIVE_GO" = "$BUILD_GO_BINARY" ]; then
            echo -e "${GREEN}✓ Correct Go binary is active: $ACTIVE_GO${NC}"
            echo -e "${GREEN}✓ Version: $ACTIVE_GO_VERSION${NC}"
        else
            echo -e "${YELLOW}⚠ Active Go differs from expected${NC}"
            echo -e "${YELLOW}  Expected: $BUILD_GO_BINARY${NC}"
            echo -e "${YELLOW}  Active: $ACTIVE_GO${NC}"
        fi
        
        # Display environment summary
        echo ""
        echo -e "${CYAN}Build Environment Summary:${NC}"
        echo -e "${CYAN}  GOROOT:      ${NC}$GOROOT"
        echo -e "${CYAN}  GOPATH:      ${NC}$GOPATH"
        echo -e "${CYAN}  GO111MODULE: ${NC}$GO111MODULE"
        echo -e "${CYAN}  CGO_ENABLED: ${NC}$CGO_ENABLED"
        echo -e "${CYAN}  Go Binary:   ${NC}$ACTIVE_GO"
        echo -e "${CYAN}  Go Version:  ${NC}$ACTIVE_GO_VERSION"
        echo ""
        
        # Verify Go version is compatible before building
        # Parse version to check compatibility
        GO_BUILD_MAJOR=$(echo "$ACTIVE_GO_VERSION" | cut -d. -f1)
        GO_BUILD_MINOR=$(echo "$ACTIVE_GO_VERSION" | cut -d. -f2)
        
        if [ "$GO_BUILD_MAJOR" = "1" ] && ([ "$GO_BUILD_MINOR" = "21" ] || [ "$GO_BUILD_MINOR" = "22" ]); then
            echo -e "${GREEN}✓ Go version is compatible for Geth build${NC}"
        else
            echo -e "${RED}✗ Go version $ACTIVE_GO_VERSION is not compatible${NC}"
            echo -e "${YELLOW}Required: Go 1.21 or 1.22${NC}"
            echo -e "${YELLOW}This should not happen after version check${NC}"
            exit 1
        fi
        
        echo ""
        echo -e "${GREEN}✅ Build environment configured successfully${NC}"
        echo ""
        
        # Change to source directory
        cd "$GETH_SRC_DIR"
        
        # Download Go modules
        echo -e "${YELLOW}Downloading Go modules...${NC}"
        if ! go mod download 2>&1; then
            echo -e "${RED}✗ Failed to download Go modules${NC}"
            cd ../..
            exit 1
        fi
        
        echo -e "${YELLOW}Tidying Go modules...${NC}"
        if ! go mod tidy 2>&1; then
            echo -e "${YELLOW}⚠ go mod tidy had warnings (non-critical)${NC}"
        fi
        
        # Build Geth
        echo ""
        echo -e "${YELLOW}Compiling Geth (this may take a few minutes)...${NC}"
        echo -e "${CYAN}Using Go $ACTIVE_GO_VERSION from $ACTIVE_GO${NC}"
        echo ""
        
        # Capture build start time
        BUILD_START=$(date +%s)
        
        # Build with verbose output for troubleshooting
        if go build -v -o geth ./cmd/geth 2>&1 | grep -E "(^#|runtime\.stopTheWorld|error|fatal)"; then
            # Check if build actually succeeded
            if [ -f "geth" ]; then
                BUILD_END=$(date +%s)
                BUILD_TIME=$((BUILD_END - BUILD_START))
                
                mv geth ../../
                cd ../..
                chmod +x geth
                
                # Get binary size
                GETH_SIZE=$(du -h geth | cut -f1)
                
                echo ""
                echo -e "${GREEN}✅ Geth built successfully${NC}"
                echo -e "${CYAN}  Build time: ${BUILD_TIME}s${NC}"
                echo -e "${CYAN}  Binary size: ${GETH_SIZE}${NC}"
                echo -e "${CYAN}  Go version used: ${ACTIVE_GO_VERSION}${NC}"
                echo ""
                
                # Run post-build validation
                if validate_geth_build "geth" "genesis.json" "$ACTIVE_GO_VERSION"; then
                    echo -e "${GREEN}✅ Post-build validation passed${NC}"
                else
                    echo -e "${RED}✗ Post-build validation failed${NC}"
                    echo -e "${YELLOW}The binary may not work correctly${NC}"
                    read -p "Continue anyway? (yes/no): " continue_build
                    if [ "$continue_build" != "yes" ]; then
                        exit 1
                    fi
                fi
            else
                echo ""
                echo -e "${RED}❌ Geth build failed${NC}"
                echo -e "${YELLOW}Build completed but binary not found${NC}"
                cd ../..
                exit 1
            fi
        else
            echo ""
            echo -e "${RED}❌ Geth build failed${NC}"
            echo -e "${YELLOW}Check the error messages above${NC}"
            cd ../..
            exit 1
        fi
    else
        echo -e "${RED}❌ Geth source not found${NC}"
        echo -e "${YELLOW}Searched in: Blockchain/node_src and SilverBitcoin/node_src${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Geth binary already exists${NC}"
    
    # Display existing binary info
    if [ -x "geth" ]; then
        GETH_SIZE=$(du -h geth | cut -f1)
        echo -e "${CYAN}  Binary size: ${GETH_SIZE}${NC}"
        
        # Try to get version
        if ./geth version &>/dev/null; then
            GETH_VERSION=$(./geth version 2>/dev/null | head -1)
            echo -e "${CYAN}  Version: ${GETH_VERSION}${NC}"
        fi
    fi
fi

echo ""

# Step 2: Generate Keys
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 2/6: Generating Validator Keys                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "scripts/setup/generate-node-keys.sh" ]; then
    chmod +x scripts/setup/generate-node-keys.sh
    # Auto-confirm for generate-node-keys.sh
    echo "yes" | scripts/setup/generate-node-keys.sh
else
    echo -e "${RED}❌ generate-node-keys.sh not found${NC}"
    exit 1
fi

echo ""

# Step 3: Genesis is already updated by generate-node-keys.sh
echo -e "${GREEN}✅ Genesis.json updated with validator addresses${NC}"
echo ""

# Step 4: Initialize Nodes
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 4/6: Initializing Nodes                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "scripts/setup/initialize-nodes.sh" ]; then
    chmod +x scripts/setup/initialize-nodes.sh
    scripts/setup/initialize-nodes.sh
else
    echo -e "${RED}❌ initialize-nodes.sh not found${NC}"
    exit 1
fi

echo ""

# Step 5: Start Nodes
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 5/6: Starting Validator Nodes                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "scripts/node-management/start-all-nodes.sh" ]; then
    chmod +x scripts/node-management/start-all-nodes.sh
    scripts/node-management/start-all-nodes.sh
else
    echo -e "${RED}❌ start-all-nodes.sh not found${NC}"
    exit 1
fi

echo ""

# Final Summary
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Blockchain Setup Complete!                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}🎉 SilverBitcoin blockchain is now running!${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  Check status:    ${CYAN}scripts/node-management/node-status.sh${NC}"
echo -e "  View nodes:      ${CYAN}tmux ls${NC}"
echo -e "  Attach to node:  ${CYAN}tmux attach -t node1${NC}"
echo -e "  Stop nodes:      ${CYAN}scripts/node-management/stop-all-nodes.sh${NC}"
echo ""
echo -e "${YELLOW}RPC Endpoint:${NC}"
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
echo -e "  ${CYAN}http://${SERVER_IP}:8546${NC}"
echo ""
echo -e "${YELLOW}Chain Info:${NC}"
echo -e "  Chain ID: ${CYAN}5200${NC}"
echo -e "  Symbol: ${CYAN}SBTC${NC}"
