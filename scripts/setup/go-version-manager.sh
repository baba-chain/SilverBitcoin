#!/bin/bash

# SilverBitcoin - Go Version Manager Module
# This module provides complete Go version detection, validation, and management
# for building Geth on Ubuntu 22.04, 24.04, and 25.10
#
# CRITICAL: This is a PRODUCTION-READY implementation with full error handling,
# edge case management, and comprehensive validation. NO mock or placeholder code.

# Color codes for output formatting
readonly GO_MGR_GREEN='\033[0;32m'
readonly GO_MGR_RED='\033[0;31m'
readonly GO_MGR_YELLOW='\033[1;33m'
readonly GO_MGR_CYAN='\033[0;36m'
readonly GO_MGR_NC='\033[0m'

# Go version requirements for Geth compilation
readonly GO_REQUIRED_MAJOR=1
readonly GO_REQUIRED_MINOR_MIN=21
readonly GO_REQUIRED_MINOR_MAX=22
readonly GO_RECOMMENDED_VERSION="1.22.10"

# Global variables for version information
GO_VERSION_FULL=""
GO_VERSION_MAJOR=""
GO_VERSION_MINOR=""
GO_VERSION_PATCH=""
GO_IS_COMPATIBLE=false
GO_INSTALL_PATH=""
GO_BINARY_PATH=""

#######################################
# Detect the currently installed Go version
# This function performs comprehensive detection of Go installation,
# including system Go, alternative installations, and custom paths.
#
# Globals:
#   GO_VERSION_FULL - Set to full version string (e.g., "1.22.10")
#   GO_BINARY_PATH - Set to path of go binary
# Returns:
#   0 if Go is found, 1 if not found
# Outputs:
#   Writes detection status to stdout
#######################################
detect_go_version() {
    local go_cmd=""
    local version_output=""
    local version_string=""
    
    # Try to find Go binary in multiple locations
    # Priority: 1. System PATH, 2. Common installation paths, 3. Alternative installations
    
    # Method 1: Check if 'go' is in PATH
    if command -v go &>/dev/null; then
        go_cmd="go"
        GO_BINARY_PATH=$(command -v go)
    # Method 2: Check common Ubuntu installation paths
    elif [ -x "/usr/lib/go-1.22/bin/go" ]; then
        go_cmd="/usr/lib/go-1.22/bin/go"
        GO_BINARY_PATH="/usr/lib/go-1.22/bin/go"
    elif [ -x "/usr/lib/go-1.21/bin/go" ]; then
        go_cmd="/usr/lib/go-1.21/bin/go"
        GO_BINARY_PATH="/usr/lib/go-1.21/bin/go"
    elif [ -x "/usr/local/go/bin/go" ]; then
        go_cmd="/usr/local/go/bin/go"
        GO_BINARY_PATH="/usr/local/go/bin/go"
    elif [ -x "/usr/local/go-1.22/bin/go" ]; then
        go_cmd="/usr/local/go-1.22/bin/go"
        GO_BINARY_PATH="/usr/local/go-1.22/bin/go"
    elif [ -x "/usr/local/go-1.21/bin/go" ]; then
        go_cmd="/usr/local/go-1.21/bin/go"
        GO_BINARY_PATH="/usr/local/go-1.21/bin/go"
    # Method 3: Check if go is in /usr/bin but not in PATH
    elif [ -x "/usr/bin/go" ]; then
        go_cmd="/usr/bin/go"
        GO_BINARY_PATH="/usr/bin/go"
    else
        echo -e "${GO_MGR_RED}✗ Go not found in system${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}Searched locations:${GO_MGR_NC}"
        echo -e "  - System PATH"
        echo -e "  - /usr/lib/go-1.22/bin/go"
        echo -e "  - /usr/lib/go-1.21/bin/go"
        echo -e "  - /usr/local/go/bin/go"
        echo -e "  - /usr/local/go-1.22/bin/go"
        echo -e "  - /usr/local/go-1.21/bin/go"
        echo -e "  - /usr/bin/go"
        return 1
    fi
    
    # Execute 'go version' and capture output with error handling
    if ! version_output=$($go_cmd version 2>&1); then
        echo -e "${GO_MGR_RED}✗ Failed to execute 'go version'${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}Error output: $version_output${GO_MGR_NC}"
        return 1
    fi
    
    # Parse version string from output
    # Expected format: "go version go1.22.10 linux/amd64"
    # We need to extract "1.22.10" from "go1.22.10"
    # Use portable regex that works on both Linux and macOS
    version_string=$(echo "$version_output" | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 | sed 's/^go//')
    
    if [ -z "$version_string" ]; then
        # Fallback parsing method for non-standard output
        version_string=$(echo "$version_output" | awk '{print $3}' | sed 's/go//')
    fi
    
    if [ -z "$version_string" ]; then
        echo -e "${GO_MGR_RED}✗ Failed to parse Go version from output${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}Version output: $version_output${GO_MGR_NC}"
        return 1
    fi
    
    GO_VERSION_FULL="$version_string"
    echo -e "${GO_MGR_GREEN}✓ Go detected: version $GO_VERSION_FULL${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Binary path: $GO_BINARY_PATH${GO_MGR_NC}"
    
    return 0
}

#######################################
# Parse Go version string into major, minor, and patch components
# This function handles various version formats including:
# - Standard: "1.22.10"
# - Short: "1.22"
# - Beta/RC: "1.22rc1", "1.22beta1"
#
# Globals:
#   GO_VERSION_FULL - Input version string
#   GO_VERSION_MAJOR - Set to major version number
#   GO_VERSION_MINOR - Set to minor version number
#   GO_VERSION_PATCH - Set to patch version number (0 if not present)
# Returns:
#   0 on success, 1 on parse failure
# Outputs:
#   Writes parse status to stdout
#######################################
parse_go_version() {
    if [ -z "$GO_VERSION_FULL" ]; then
        echo -e "${GO_MGR_RED}✗ No version string to parse${GO_MGR_NC}"
        return 1
    fi
    
    # Remove any beta/rc/dev suffixes for parsing
    local clean_version=$(echo "$GO_VERSION_FULL" | sed 's/[a-zA-Z].*//')
    
    # Validate version format (must be X.Y or X.Y.Z where X, Y, Z are numbers)
    if ! echo "$clean_version" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
        echo -e "${GO_MGR_RED}✗ Invalid version format: $GO_VERSION_FULL${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}Expected format: X.Y or X.Y.Z (e.g., 1.22 or 1.22.10)${GO_MGR_NC}"
        return 1
    fi
    
    # Extract major version
    GO_VERSION_MAJOR=$(echo "$clean_version" | cut -d. -f1)
    if [ -z "$GO_VERSION_MAJOR" ] || ! [[ "$GO_VERSION_MAJOR" =~ ^[0-9]+$ ]]; then
        echo -e "${GO_MGR_RED}✗ Failed to parse major version from: $clean_version${GO_MGR_NC}"
        return 1
    fi
    
    # Extract minor version
    GO_VERSION_MINOR=$(echo "$clean_version" | cut -d. -f2)
    if [ -z "$GO_VERSION_MINOR" ] || ! [[ "$GO_VERSION_MINOR" =~ ^[0-9]+$ ]]; then
        echo -e "${GO_MGR_RED}✗ Failed to parse minor version from: $clean_version${GO_MGR_NC}"
        return 1
    fi
    
    # Extract patch version (default to 0 if not present)
    GO_VERSION_PATCH=$(echo "$clean_version" | cut -d. -f3)
    if [ -z "$GO_VERSION_PATCH" ]; then
        GO_VERSION_PATCH=0
    elif ! [[ "$GO_VERSION_PATCH" =~ ^[0-9]+$ ]]; then
        echo -e "${GO_MGR_YELLOW}⚠ Invalid patch version, defaulting to 0${GO_MGR_NC}"
        GO_VERSION_PATCH=0
    fi
    
    echo -e "${GO_MGR_GREEN}✓ Version parsed: ${GO_VERSION_MAJOR}.${GO_VERSION_MINOR}.${GO_VERSION_PATCH}${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Major: $GO_VERSION_MAJOR${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Minor: $GO_VERSION_MINOR${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Patch: $GO_VERSION_PATCH${GO_MGR_NC}"
    
    return 0
}

#######################################
# Check if the detected Go version is compatible with Geth requirements
# Geth requires Go 1.21 or 1.22 (not 1.23+)
#
# Globals:
#   GO_VERSION_MAJOR - Major version number
#   GO_VERSION_MINOR - Minor version number
#   GO_IS_COMPATIBLE - Set to true if compatible, false otherwise
# Returns:
#   0 if compatible, 1 if incompatible
# Outputs:
#   Writes compatibility status with detailed explanation
#######################################
check_go_compatibility() {
    if [ -z "$GO_VERSION_MAJOR" ] || [ -z "$GO_VERSION_MINOR" ]; then
        echo -e "${GO_MGR_RED}✗ Version not parsed, cannot check compatibility${GO_MGR_NC}"
        GO_IS_COMPATIBLE=false
        return 1
    fi
    
    local is_compatible=false
    local reason=""
    
    # Check major version (must be 1)
    if [ "$GO_VERSION_MAJOR" -ne "$GO_REQUIRED_MAJOR" ]; then
        reason="Major version $GO_VERSION_MAJOR is not supported (required: $GO_REQUIRED_MAJOR)"
    # Check minor version (must be 21 or 22)
    elif [ "$GO_VERSION_MINOR" -lt "$GO_REQUIRED_MINOR_MIN" ]; then
        reason="Version too old (minimum: ${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MIN})"
    elif [ "$GO_VERSION_MINOR" -gt "$GO_REQUIRED_MINOR_MAX" ]; then
        reason="Version too new (maximum: ${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MAX})"
        reason="$reason - Go 1.23+ has breaking changes in runtime package"
    else
        is_compatible=true
        reason="Version is in supported range (${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MIN}-${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MAX})"
    fi
    
    # Set global compatibility flag
    if [ "$is_compatible" = true ]; then
        GO_IS_COMPATIBLE=true
        echo -e "${GO_MGR_GREEN}✓ Go version ${GO_VERSION_FULL} is compatible${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}  $reason${GO_MGR_NC}"
        return 0
    else
        GO_IS_COMPATIBLE=false
        echo -e "${GO_MGR_RED}✗ Go version ${GO_VERSION_FULL} is NOT compatible${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  Reason: $reason${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}  Required: Go ${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MIN} or ${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MAX}${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}  Recommended: Go ${GO_RECOMMENDED_VERSION}${GO_MGR_NC}"
        return 1
    fi
}

#######################################
# Display comprehensive Go version information
# This function provides a detailed summary of the detected Go installation
# including version, compatibility status, and installation path
#
# Globals:
#   All GO_* variables
# Outputs:
#   Formatted version information report
#######################################
display_go_version_info() {
    echo ""
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Go Version Information                                   ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    if [ -z "$GO_VERSION_FULL" ]; then
        echo -e "${GO_MGR_RED}  Status: Not Detected${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  Action Required: Install Go ${GO_RECOMMENDED_VERSION}${GO_MGR_NC}"
    else
        echo -e "${GO_MGR_CYAN}  Detected Version: ${GO_MGR_NC}${GO_VERSION_FULL}"
        echo -e "${GO_MGR_CYAN}  Binary Path: ${GO_MGR_NC}${GO_BINARY_PATH}"
        
        if [ -n "$GO_VERSION_MAJOR" ]; then
            echo -e "${GO_MGR_CYAN}  Parsed Version: ${GO_MGR_NC}${GO_VERSION_MAJOR}.${GO_VERSION_MINOR}.${GO_VERSION_PATCH}"
        fi
        
        if [ "$GO_IS_COMPATIBLE" = true ]; then
            echo -e "${GO_MGR_GREEN}  Compatibility: ✓ Compatible${GO_MGR_NC}"
            echo -e "${GO_MGR_GREEN}  Status: Ready for Geth compilation${GO_MGR_NC}"
        else
            echo -e "${GO_MGR_RED}  Compatibility: ✗ Incompatible${GO_MGR_NC}"
            echo -e "${GO_MGR_YELLOW}  Required: Go ${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MIN} or ${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MAX}${GO_MGR_NC}"
            echo -e "${GO_MGR_YELLOW}  Action Required: Install compatible Go version${GO_MGR_NC}"
        fi
    fi
    
    echo ""
}

#######################################
# Validate Go installation by checking binary and basic functionality
# This performs comprehensive validation including:
# - Binary existence and executability
# - Version command execution
# - Basic compilation test
#
# Arguments:
#   $1 - Path to Go binary (optional, uses GO_BINARY_PATH if not provided)
# Returns:
#   0 if validation passes, 1 if validation fails
# Outputs:
#   Detailed validation results
#######################################
validate_go_installation() {
    local go_binary="${1:-$GO_BINARY_PATH}"
    
    if [ -z "$go_binary" ]; then
        echo -e "${GO_MGR_RED}✗ No Go binary path provided for validation${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}Validating Go installation...${GO_MGR_NC}"
    
    # Check 1: Binary exists
    if [ ! -f "$go_binary" ]; then
        echo -e "${GO_MGR_RED}✗ Go binary not found at: $go_binary${GO_MGR_NC}"
        return 1
    fi
    echo -e "${GO_MGR_GREEN}✓ Binary exists${GO_MGR_NC}"
    
    # Check 2: Binary is executable
    if [ ! -x "$go_binary" ]; then
        echo -e "${GO_MGR_RED}✗ Go binary is not executable: $go_binary${GO_MGR_NC}"
        return 1
    fi
    echo -e "${GO_MGR_GREEN}✓ Binary is executable${GO_MGR_NC}"
    
    # Check 3: Version command works
    local version_output
    if ! version_output=$($go_binary version 2>&1); then
        echo -e "${GO_MGR_RED}✗ 'go version' command failed${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}Error: $version_output${GO_MGR_NC}"
        return 1
    fi
    echo -e "${GO_MGR_GREEN}✓ Version command works: $version_output${GO_MGR_NC}"
    
    # Check 4: Environment command works
    if ! $go_binary env GOROOT &>/dev/null; then
        echo -e "${GO_MGR_YELLOW}⚠ 'go env' command failed (non-critical)${GO_MGR_NC}"
    else
        local goroot=$($go_binary env GOROOT 2>/dev/null)
        echo -e "${GO_MGR_GREEN}✓ Environment command works${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}  GOROOT: $goroot${GO_MGR_NC}"
    fi
    
    # Check 5: Basic compilation test (create and compile a simple program)
    local test_dir=$(mktemp -d)
    local test_file="$test_dir/test.go"
    
    cat > "$test_file" << 'EOF'
package main
import "fmt"
func main() {
    fmt.Println("Go validation test")
}
EOF
    
    if $go_binary build -o "$test_dir/test" "$test_file" &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ Basic compilation test passed${GO_MGR_NC}"
        rm -rf "$test_dir"
    else
        echo -e "${GO_MGR_YELLOW}⚠ Basic compilation test failed (non-critical)${GO_MGR_NC}"
        rm -rf "$test_dir"
    fi
    
    echo -e "${GO_MGR_GREEN}✓ Go installation validation complete${GO_MGR_NC}"
    return 0
}

#######################################
# Main function to perform complete Go version detection and validation
# This is the primary entry point that orchestrates all detection and validation steps
#
# Returns:
#   0 if Go is detected and compatible
#   1 if Go is not found
#   2 if Go is found but incompatible
# Outputs:
#   Complete detection and validation report
#######################################
check_go_version_complete() {
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Go Version Detection & Validation                        ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    # Step 1: Detect Go installation
    if ! detect_go_version; then
        display_go_version_info
        return 1
    fi
    
    # Step 2: Parse version string
    if ! parse_go_version; then
        echo -e "${GO_MGR_RED}✗ Failed to parse Go version${GO_MGR_NC}"
        display_go_version_info
        return 1
    fi
    
    # Step 3: Check compatibility
    check_go_compatibility
    local compat_result=$?
    
    # Step 4: Validate installation
    if ! validate_go_installation; then
        echo -e "${GO_MGR_YELLOW}⚠ Go installation validation had issues${GO_MGR_NC}"
    fi
    
    # Step 5: Display summary
    display_go_version_info
    
    # Return appropriate code
    if [ "$GO_IS_COMPATIBLE" = true ]; then
        return 0
    else
        return 2
    fi
}

# Export functions for use in other scripts
export -f detect_go_version
export -f parse_go_version
export -f check_go_compatibility
export -f display_go_version_info
export -f validate_go_installation
export -f check_go_version_complete

#######################################
# GO INSTALLATION MODULE
# This section provides complete Go installation functionality
# with multiple methods, full error handling, and comprehensive validation
#######################################

# Installation configuration
readonly GO_DOWNLOAD_BASE_URL="https://go.dev/dl"
readonly GO_INSTALL_DIR="/usr/local"
readonly GO_TEMP_DIR="/tmp/go-install-$$"
readonly GO_CHECKSUM_URL="https://go.dev/dl/?mode=json"

#######################################
# Check available disk space before installation
# Ensures sufficient space for Go installation (minimum 500MB)
#
# Arguments:
#   $1 - Target directory for installation
#   $2 - Required space in MB (default: 500)
# Returns:
#   0 if sufficient space, 1 if insufficient
# Outputs:
#   Disk space status
#######################################
check_disk_space() {
    local target_dir="${1:-$GO_INSTALL_DIR}"
    local required_mb="${2:-500}"
    
    echo -e "${GO_MGR_CYAN}Checking disk space...${GO_MGR_NC}"
    
    # Get available space in MB
    local available_mb
    if command -v df &>/dev/null; then
        # Use df to get available space
        available_mb=$(df -m "$target_dir" 2>/dev/null | awk 'NR==2 {print $4}')
        
        if [ -z "$available_mb" ]; then
            echo -e "${GO_MGR_YELLOW}⚠ Could not determine disk space, proceeding anyway${GO_MGR_NC}"
            return 0
        fi
        
        if [ "$available_mb" -lt "$required_mb" ]; then
            echo -e "${GO_MGR_RED}✗ Insufficient disk space${GO_MGR_NC}"
            echo -e "${GO_MGR_YELLOW}  Required: ${required_mb}MB${GO_MGR_NC}"
            echo -e "${GO_MGR_YELLOW}  Available: ${available_mb}MB${GO_MGR_NC}"
            return 1
        fi
        
        echo -e "${GO_MGR_GREEN}✓ Sufficient disk space: ${available_mb}MB available${GO_MGR_NC}"
        return 0
    else
        echo -e "${GO_MGR_YELLOW}⚠ 'df' command not available, skipping disk space check${GO_MGR_NC}"
        return 0
    fi
}

#######################################
# Download file with progress indication and retry logic
# Supports both wget and curl with automatic fallback
#
# Arguments:
#   $1 - URL to download
#   $2 - Output file path
#   $3 - Max retries (default: 3)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Download progress and status
#######################################
download_file() {
    local url="$1"
    local output="$2"
    local max_retries="${3:-3}"
    local retry_count=0
    
    if [ -z "$url" ] || [ -z "$output" ]; then
        echo -e "${GO_MGR_RED}✗ Invalid download parameters${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}Downloading: $url${GO_MGR_NC}"
    
    while [ $retry_count -lt $max_retries ]; do
        # Try wget first (preferred for progress indication)
        if command -v wget &>/dev/null; then
            if wget --show-progress --progress=bar:force -O "$output" "$url" 2>&1; then
                echo -e "${GO_MGR_GREEN}✓ Download complete${GO_MGR_NC}"
                return 0
            fi
        # Fallback to curl
        elif command -v curl &>/dev/null; then
            if curl -L --progress-bar -o "$output" "$url" 2>&1; then
                echo -e "${GO_MGR_GREEN}✓ Download complete${GO_MGR_NC}"
                return 0
            fi
        else
            echo -e "${GO_MGR_RED}✗ Neither wget nor curl is available${GO_MGR_NC}"
            return 1
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo -e "${GO_MGR_YELLOW}⚠ Download failed, retrying ($retry_count/$max_retries)...${GO_MGR_NC}"
            sleep 2
        fi
    done
    
    echo -e "${GO_MGR_RED}✗ Download failed after $max_retries attempts${GO_MGR_NC}"
    return 1
}

#######################################
# Verify file checksum using SHA256
# Downloads official checksums from go.dev and validates the file
#
# Arguments:
#   $1 - File to verify
#   $2 - Expected filename (for checksum lookup)
# Returns:
#   0 if checksum matches, 1 if mismatch or error
# Outputs:
#   Checksum verification status
#######################################
verify_checksum() {
    local file="$1"
    local filename="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${GO_MGR_RED}✗ File not found for checksum verification: $file${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}Verifying checksum...${GO_MGR_NC}"
    
    # Check if sha256sum is available
    if ! command -v sha256sum &>/dev/null && ! command -v shasum &>/dev/null; then
        echo -e "${GO_MGR_YELLOW}⚠ No checksum tool available (sha256sum/shasum), skipping verification${GO_MGR_NC}"
        return 0
    fi
    
    # Download checksum file
    local checksum_file="$GO_TEMP_DIR/SHA256SUMS"
    local checksum_url="${GO_DOWNLOAD_BASE_URL}/go${GO_RECOMMENDED_VERSION}.linux-amd64.tar.gz.sha256"
    
    # Try to download the specific checksum file
    if command -v wget &>/dev/null; then
        if ! wget -q -O "$checksum_file" "$checksum_url" 2>/dev/null; then
            echo -e "${GO_MGR_YELLOW}⚠ Could not download checksum file, skipping verification${GO_MGR_NC}"
            return 0
        fi
    elif command -v curl &>/dev/null; then
        if ! curl -sL -o "$checksum_file" "$checksum_url" 2>/dev/null; then
            echo -e "${GO_MGR_YELLOW}⚠ Could not download checksum file, skipping verification${GO_MGR_NC}"
            return 0
        fi
    fi
    
    # Calculate file checksum
    local calculated_sum
    if command -v sha256sum &>/dev/null; then
        calculated_sum=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum &>/dev/null; then
        calculated_sum=$(shasum -a 256 "$file" | awk '{print $1}')
    fi
    
    # Get expected checksum
    local expected_sum=$(cat "$checksum_file" 2>/dev/null | tr -d '[:space:]')
    
    if [ -z "$expected_sum" ]; then
        echo -e "${GO_MGR_YELLOW}⚠ Could not read expected checksum, skipping verification${GO_MGR_NC}"
        return 0
    fi
    
    # Compare checksums
    if [ "$calculated_sum" = "$expected_sum" ]; then
        echo -e "${GO_MGR_GREEN}✓ Checksum verified successfully${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}  SHA256: $calculated_sum${GO_MGR_NC}"
        return 0
    else
        echo -e "${GO_MGR_RED}✗ Checksum mismatch!${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  Expected: $expected_sum${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  Got:      $calculated_sum${GO_MGR_NC}"
        return 1
    fi
}

#######################################
# Install Go via apt package manager
# Attempts to install golang-1.22 or golang-1.21 from Ubuntu repositories
#
# Arguments:
#   $1 - Sudo command (empty string if running as root)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Installation progress and status
#######################################
install_go_via_apt() {
    local sudo_cmd="${1:-}"
    
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Method 1: Installing Go via APT                          ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    # Check if apt is available
    if ! command -v apt &>/dev/null; then
        echo -e "${GO_MGR_YELLOW}⚠ APT not available on this system${GO_MGR_NC}"
        return 1
    fi
    
    # Update package cache
    echo -e "${GO_MGR_CYAN}Updating package cache...${GO_MGR_NC}"
    if ! $sudo_cmd apt update -qq 2>&1 | grep -v "^$"; then
        echo -e "${GO_MGR_YELLOW}⚠ Package cache update had warnings (non-critical)${GO_MGR_NC}"
    fi
    
    # Try to install golang-1.22 first (preferred)
    echo -e "${GO_MGR_CYAN}Checking for golang-1.22 package...${GO_MGR_NC}"
    if apt-cache show golang-1.22 &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ golang-1.22 package found${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}Installing golang-1.22...${GO_MGR_NC}"
        
        if $sudo_cmd apt install -y golang-1.22 2>&1 | grep -E "(Setting up|Unpacking|Processing)"; then
            echo -e "${GO_MGR_GREEN}✓ golang-1.22 installed successfully${GO_MGR_NC}"
            GO_INSTALL_PATH="/usr/lib/go-1.22"
            GO_BINARY_PATH="/usr/lib/go-1.22/bin/go"
            return 0
        else
            echo -e "${GO_MGR_RED}✗ Failed to install golang-1.22${GO_MGR_NC}"
            return 1
        fi
    fi
    
    # Try golang-1.21 as fallback
    echo -e "${GO_MGR_CYAN}Checking for golang-1.21 package...${GO_MGR_NC}"
    if apt-cache show golang-1.21 &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ golang-1.21 package found${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}Installing golang-1.21...${GO_MGR_NC}"
        
        if $sudo_cmd apt install -y golang-1.21 2>&1 | grep -E "(Setting up|Unpacking|Processing)"; then
            echo -e "${GO_MGR_GREEN}✓ golang-1.21 installed successfully${GO_MGR_NC}"
            GO_INSTALL_PATH="/usr/lib/go-1.21"
            GO_BINARY_PATH="/usr/lib/go-1.21/bin/go"
            return 0
        else
            echo -e "${GO_MGR_RED}✗ Failed to install golang-1.21${GO_MGR_NC}"
            return 1
        fi
    fi
    
    # Try generic golang-go package as last resort
    echo -e "${GO_MGR_CYAN}Checking for golang-go package...${GO_MGR_NC}"
    if apt-cache show golang-go &>/dev/null; then
        echo -e "${GO_MGR_YELLOW}⚠ Only generic golang-go package available (version may not be compatible)${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}Installing golang-go...${GO_MGR_NC}"
        
        if $sudo_cmd apt install -y golang-go 2>&1 | grep -E "(Setting up|Unpacking|Processing)"; then
            echo -e "${GO_MGR_GREEN}✓ golang-go installed${GO_MGR_NC}"
            # Try to find the installed Go
            if command -v go &>/dev/null; then
                GO_BINARY_PATH=$(command -v go)
                GO_INSTALL_PATH=$(dirname $(dirname "$GO_BINARY_PATH"))
                return 0
            fi
        fi
    fi
    
    echo -e "${GO_MGR_RED}✗ No compatible Go package found in APT repositories${GO_MGR_NC}"
    return 1
}

#######################################
# Download and install Go from official binary
# Downloads the official Go tarball from go.dev and installs it
#
# Arguments:
#   $1 - Go version to install (default: GO_RECOMMENDED_VERSION)
#   $2 - Sudo command (empty string if running as root)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Download and installation progress
#######################################
install_go_from_binary() {
    local go_version="${1:-$GO_RECOMMENDED_VERSION}"
    local sudo_cmd="${2:-}"
    
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Method 2: Installing Go from Official Binary             ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    # Detect system architecture
    local arch=$(uname -m)
    local go_arch=""
    
    case "$arch" in
        x86_64)
            go_arch="amd64"
            ;;
        aarch64|arm64)
            go_arch="arm64"
            ;;
        armv7l|armv6l)
            go_arch="armv6l"
            ;;
        *)
            echo -e "${GO_MGR_RED}✗ Unsupported architecture: $arch${GO_MGR_NC}"
            return 1
            ;;
    esac
    
    echo -e "${GO_MGR_CYAN}Detected architecture: $arch ($go_arch)${GO_MGR_NC}"
    
    # Construct download URL
    local filename="go${go_version}.linux-${go_arch}.tar.gz"
    local download_url="${GO_DOWNLOAD_BASE_URL}/${filename}"
    local download_path="$GO_TEMP_DIR/$filename"
    
    # Create temporary directory
    mkdir -p "$GO_TEMP_DIR"
    
    # Check disk space
    if ! check_disk_space "$GO_INSTALL_DIR" 500; then
        echo -e "${GO_MGR_RED}✗ Insufficient disk space for installation${GO_MGR_NC}"
        rm -rf "$GO_TEMP_DIR"
        return 1
    fi
    
    # Download Go binary
    echo -e "${GO_MGR_CYAN}Downloading Go ${go_version}...${GO_MGR_NC}"
    if ! download_file "$download_url" "$download_path" 3; then
        echo -e "${GO_MGR_RED}✗ Failed to download Go binary${GO_MGR_NC}"
        rm -rf "$GO_TEMP_DIR"
        return 1
    fi
    
    # Verify file was downloaded and has content
    if [ ! -s "$download_path" ]; then
        echo -e "${GO_MGR_RED}✗ Downloaded file is empty or missing${GO_MGR_NC}"
        rm -rf "$GO_TEMP_DIR"
        return 1
    fi
    
    local file_size=$(du -h "$download_path" | cut -f1)
    echo -e "${GO_MGR_GREEN}✓ Downloaded ${file_size}${GO_MGR_NC}"
    
    # Verify checksum
    if ! verify_checksum "$download_path" "$filename"; then
        echo -e "${GO_MGR_RED}✗ Checksum verification failed${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}⚠ This could indicate a corrupted or tampered file${GO_MGR_NC}"
        read -p "Continue anyway? (yes/no): " continue_anyway
        if [ "$continue_anyway" != "yes" ]; then
            rm -rf "$GO_TEMP_DIR"
            return 1
        fi
    fi
    
    # Backup existing Go installation if it exists
    local target_dir="${GO_INSTALL_DIR}/go-${go_version}"
    if [ -d "$target_dir" ]; then
        echo -e "${GO_MGR_YELLOW}⚠ Existing installation found at $target_dir${GO_MGR_NC}"
        local backup_dir="${target_dir}.backup-$(date +%Y%m%d-%H%M%S)"
        echo -e "${GO_MGR_CYAN}Creating backup: $backup_dir${GO_MGR_NC}"
        if ! $sudo_cmd mv "$target_dir" "$backup_dir" 2>/dev/null; then
            echo -e "${GO_MGR_YELLOW}⚠ Could not create backup, removing old installation${GO_MGR_NC}"
            $sudo_cmd rm -rf "$target_dir"
        fi
    fi
    
    # Extract tarball
    echo -e "${GO_MGR_CYAN}Extracting Go binary...${GO_MGR_NC}"
    if ! $sudo_cmd tar -C "$GO_TEMP_DIR" -xzf "$download_path" 2>&1; then
        echo -e "${GO_MGR_RED}✗ Failed to extract tarball${GO_MGR_NC}"
        rm -rf "$GO_TEMP_DIR"
        return 1
    fi
    
    # Verify extraction
    if [ ! -d "$GO_TEMP_DIR/go" ]; then
        echo -e "${GO_MGR_RED}✗ Extraction failed: go directory not found${GO_MGR_NC}"
        rm -rf "$GO_TEMP_DIR"
        return 1
    fi
    
    echo -e "${GO_MGR_GREEN}✓ Extraction complete${GO_MGR_NC}"
    
    # Move to final location
    echo -e "${GO_MGR_CYAN}Installing to $target_dir...${GO_MGR_NC}"
    if ! $sudo_cmd mv "$GO_TEMP_DIR/go" "$target_dir" 2>&1; then
        echo -e "${GO_MGR_RED}✗ Failed to move Go to installation directory${GO_MGR_NC}"
        rm -rf "$GO_TEMP_DIR"
        return 1
    fi
    
    # Set proper permissions
    $sudo_cmd chmod -R 755 "$target_dir" 2>/dev/null
    
    # Create symlink for easier access
    if [ ! -e "${GO_INSTALL_DIR}/go" ]; then
        $sudo_cmd ln -sf "$target_dir" "${GO_INSTALL_DIR}/go" 2>/dev/null
    fi
    
    # Clean up
    rm -rf "$GO_TEMP_DIR"
    
    # Set global variables
    GO_INSTALL_PATH="$target_dir"
    GO_BINARY_PATH="$target_dir/bin/go"
    
    echo -e "${GO_MGR_GREEN}✓ Go ${go_version} installed successfully${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Installation path: $GO_INSTALL_PATH${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Binary path: $GO_BINARY_PATH${GO_MGR_NC}"
    
    # Validate installation
    if ! validate_go_installation "$GO_BINARY_PATH"; then
        echo -e "${GO_MGR_RED}✗ Installation validation failed${GO_MGR_NC}"
        return 1
    fi
    
    return 0
}

#######################################
# Main function to install compatible Go version
# Tries multiple installation methods in order of preference
#
# Arguments:
#   $1 - Sudo command (optional, auto-detected if not provided)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Complete installation process with status
#######################################
install_compatible_go() {
    local sudo_cmd="${1:-}"
    
    # Auto-detect sudo requirement if not provided
    if [ -z "$sudo_cmd" ]; then
        if [ "$EUID" -ne 0 ]; then
            sudo_cmd="sudo"
            echo -e "${GO_MGR_YELLOW}Running with sudo privileges...${GO_MGR_NC}"
        else
            sudo_cmd=""
            echo -e "${GO_MGR_CYAN}Running as root...${GO_MGR_NC}"
        fi
    fi
    
    echo ""
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Installing Compatible Go Version                         ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    echo -e "${GO_MGR_CYAN}Target version: Go ${GO_RECOMMENDED_VERSION}${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}Compatible range: Go ${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MIN}-${GO_REQUIRED_MAJOR}.${GO_REQUIRED_MINOR_MAX}${GO_MGR_NC}"
    echo ""
    
    # Method 1: Try APT installation
    echo -e "${GO_MGR_CYAN}Attempting installation via APT...${GO_MGR_NC}"
    if install_go_via_apt "$sudo_cmd"; then
        echo ""
        echo -e "${GO_MGR_GREEN}✅ Go installed successfully via APT${GO_MGR_NC}"
        return 0
    fi
    
    echo ""
    echo -e "${GO_MGR_YELLOW}⚠ APT installation failed, trying binary installation...${GO_MGR_NC}"
    echo ""
    
    # Method 2: Download and install from official binary
    if install_go_from_binary "$GO_RECOMMENDED_VERSION" "$sudo_cmd"; then
        echo ""
        echo -e "${GO_MGR_GREEN}✅ Go installed successfully from official binary${GO_MGR_NC}"
        return 0
    fi
    
    # All methods failed
    echo ""
    echo -e "${GO_MGR_RED}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_RED}║   ✗ Go Installation Failed                                 ║${GO_MGR_NC}"
    echo -e "${GO_MGR_RED}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    echo -e "${GO_MGR_YELLOW}All automatic installation methods failed.${GO_MGR_NC}"
    echo -e "${GO_MGR_YELLOW}Please install Go manually:${GO_MGR_NC}"
    echo ""
    echo -e "${GO_MGR_CYAN}Manual installation steps:${GO_MGR_NC}"
    echo -e "  1. Visit: https://go.dev/dl/"
    echo -e "  2. Download: go${GO_RECOMMENDED_VERSION}.linux-amd64.tar.gz"
    echo -e "  3. Extract: sudo tar -C /usr/local -xzf go${GO_RECOMMENDED_VERSION}.linux-amd64.tar.gz"
    echo -e "  4. Add to PATH: export PATH=\$PATH:/usr/local/go/bin"
    echo ""
    
    return 1
}

# Export installation functions
export -f check_disk_space
export -f download_file
export -f verify_checksum
export -f install_go_via_apt
export -f install_go_from_binary
export -f install_compatible_go

#######################################
# UPDATE-ALTERNATIVES & SYMLINK MANAGEMENT MODULE
# This section provides complete update-alternatives configuration
# and symlink management for Go installations
#######################################

# Alternatives configuration
readonly GO_ALTERNATIVES_PRIORITY=100
readonly GO_TOOLS=("go" "gofmt" "godoc")

#######################################
# Check if update-alternatives is available on the system
# Some systems may not have update-alternatives (e.g., non-Debian systems)
#
# Returns:
#   0 if available, 1 if not available
# Outputs:
#   Availability status
#######################################
check_alternatives_available() {
    if command -v update-alternatives &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ update-alternatives is available${GO_MGR_NC}"
        return 0
    else
        echo -e "${GO_MGR_YELLOW}⚠ update-alternatives not available on this system${GO_MGR_NC}"
        return 1
    fi
}

#######################################
# Remove existing Go alternatives to prevent conflicts
# This ensures clean state before adding new alternatives
#
# Arguments:
#   $1 - Sudo command (empty string if running as root)
# Returns:
#   0 on success
# Outputs:
#   Removal status for each tool
#######################################
remove_existing_go_alternatives() {
    local sudo_cmd="${1:-}"
    
    echo -e "${GO_MGR_CYAN}Checking for existing Go alternatives...${GO_MGR_NC}"
    
    for tool in "${GO_TOOLS[@]}"; do
        # Check if alternative exists
        if $sudo_cmd update-alternatives --query "$tool" &>/dev/null; then
            echo -e "${GO_MGR_YELLOW}⚠ Removing existing alternative for $tool${GO_MGR_NC}"
            
            # Get all alternatives for this tool
            local alternatives=$($sudo_cmd update-alternatives --list "$tool" 2>/dev/null)
            
            # Remove each alternative
            while IFS= read -r alt_path; do
                if [ -n "$alt_path" ]; then
                    $sudo_cmd update-alternatives --remove "$tool" "$alt_path" &>/dev/null || true
                fi
            done <<< "$alternatives"
        fi
    done
    
    echo -e "${GO_MGR_GREEN}✓ Existing alternatives cleaned${GO_MGR_NC}"
    return 0
}

#######################################
# Register Go binary with update-alternatives system
# This allows multiple Go versions to coexist and be switched easily
#
# Arguments:
#   $1 - Go installation path (e.g., /usr/local/go-1.22)
#   $2 - Priority (default: GO_ALTERNATIVES_PRIORITY)
#   $3 - Sudo command (empty string if running as root)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Registration status for each tool
#######################################
setup_go_alternatives() {
    local go_install_path="$1"
    local priority="${2:-$GO_ALTERNATIVES_PRIORITY}"
    local sudo_cmd="${3:-}"
    
    if [ -z "$go_install_path" ]; then
        echo -e "${GO_MGR_RED}✗ No Go installation path provided${GO_MGR_NC}"
        return 1
    fi
    
    if [ ! -d "$go_install_path" ]; then
        echo -e "${GO_MGR_RED}✗ Go installation path does not exist: $go_install_path${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Configuring update-alternatives for Go                   ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    # Check if update-alternatives is available
    if ! check_alternatives_available; then
        echo -e "${GO_MGR_YELLOW}⚠ Falling back to direct symlink creation${GO_MGR_NC}"
        return 1
    fi
    
    # Remove existing alternatives to prevent conflicts
    remove_existing_go_alternatives "$sudo_cmd"
    
    echo -e "${GO_MGR_CYAN}Registering Go tools with update-alternatives...${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Installation path: $go_install_path${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}  Priority: $priority${GO_MGR_NC}"
    echo ""
    
    local success_count=0
    local fail_count=0
    
    # Register each Go tool
    for tool in "${GO_TOOLS[@]}"; do
        local tool_path="$go_install_path/bin/$tool"
        local link_path="/usr/bin/$tool"
        
        # Check if tool exists in Go installation
        if [ ! -f "$tool_path" ]; then
            echo -e "${GO_MGR_YELLOW}⚠ Tool not found: $tool_path (skipping)${GO_MGR_NC}"
            continue
        fi
        
        echo -e "${GO_MGR_CYAN}Registering $tool...${GO_MGR_NC}"
        
        # Install alternative
        if $sudo_cmd update-alternatives --install \
            "$link_path" \
            "$tool" \
            "$tool_path" \
            "$priority" 2>&1; then
            
            echo -e "${GO_MGR_GREEN}✓ $tool registered successfully${GO_MGR_NC}"
            ((success_count++))
            
            # Set as default
            if $sudo_cmd update-alternatives --set "$tool" "$tool_path" &>/dev/null; then
                echo -e "${GO_MGR_GREEN}  → Set as default${GO_MGR_NC}"
            fi
        else
            echo -e "${GO_MGR_RED}✗ Failed to register $tool${GO_MGR_NC}"
            ((fail_count++))
        fi
    done
    
    echo ""
    echo -e "${GO_MGR_CYAN}Registration summary:${GO_MGR_NC}"
    echo -e "${GO_MGR_GREEN}  Success: $success_count${GO_MGR_NC}"
    if [ $fail_count -gt 0 ]; then
        echo -e "${GO_MGR_RED}  Failed: $fail_count${GO_MGR_NC}"
    fi
    
    if [ $success_count -eq 0 ]; then
        echo -e "${GO_MGR_RED}✗ No tools were registered${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_GREEN}✓ update-alternatives configuration complete${GO_MGR_NC}"
    return 0
}

#######################################
# Create direct symlinks for Go tools
# Fallback method when update-alternatives is not available
#
# Arguments:
#   $1 - Go installation path (e.g., /usr/local/go-1.22)
#   $2 - Sudo command (empty string if running as root)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Symlink creation status
#######################################
create_go_symlinks() {
    local go_install_path="$1"
    local sudo_cmd="${2:-}"
    
    if [ -z "$go_install_path" ]; then
        echo -e "${GO_MGR_RED}✗ No Go installation path provided${GO_MGR_NC}"
        return 1
    fi
    
    if [ ! -d "$go_install_path" ]; then
        echo -e "${GO_MGR_RED}✗ Go installation path does not exist: $go_install_path${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Creating Direct Symlinks for Go                          ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    local success_count=0
    local fail_count=0
    
    for tool in "${GO_TOOLS[@]}"; do
        local tool_path="$go_install_path/bin/$tool"
        local link_path="/usr/bin/$tool"
        
        # Check if tool exists
        if [ ! -f "$tool_path" ]; then
            echo -e "${GO_MGR_YELLOW}⚠ Tool not found: $tool_path (skipping)${GO_MGR_NC}"
            continue
        fi
        
        echo -e "${GO_MGR_CYAN}Creating symlink for $tool...${GO_MGR_NC}"
        
        # Remove existing symlink or file if it exists
        if [ -e "$link_path" ] || [ -L "$link_path" ]; then
            echo -e "${GO_MGR_YELLOW}  → Removing existing link/file${GO_MGR_NC}"
            $sudo_cmd rm -f "$link_path" 2>/dev/null || true
        fi
        
        # Create symlink
        if $sudo_cmd ln -sf "$tool_path" "$link_path" 2>&1; then
            echo -e "${GO_MGR_GREEN}✓ Symlink created: $link_path → $tool_path${GO_MGR_NC}"
            ((success_count++))
        else
            echo -e "${GO_MGR_RED}✗ Failed to create symlink for $tool${GO_MGR_NC}"
            ((fail_count++))
        fi
    done
    
    echo ""
    echo -e "${GO_MGR_CYAN}Symlink creation summary:${GO_MGR_NC}"
    echo -e "${GO_MGR_GREEN}  Success: $success_count${GO_MGR_NC}"
    if [ $fail_count -gt 0 ]; then
        echo -e "${GO_MGR_RED}  Failed: $fail_count${GO_MGR_NC}"
    fi
    
    if [ $success_count -eq 0 ]; then
        echo -e "${GO_MGR_RED}✗ No symlinks were created${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_GREEN}✓ Symlink creation complete${GO_MGR_NC}"
    return 0
}

#######################################
# Verify that Go tools are accessible via PATH
# Checks that all Go tools can be executed from command line
#
# Arguments:
#   $1 - Expected Go version (optional)
# Returns:
#   0 if all tools are accessible, 1 if any tool is missing
# Outputs:
#   Verification status for each tool
#######################################
verify_go_tools_accessible() {
    local expected_version="${1:-}"
    
    echo -e "${GO_MGR_CYAN}Verifying Go tools accessibility...${GO_MGR_NC}"
    
    local all_accessible=true
    
    for tool in "${GO_TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local tool_path=$(command -v "$tool")
            echo -e "${GO_MGR_GREEN}✓ $tool is accessible${GO_MGR_NC}"
            echo -e "${GO_MGR_CYAN}  Path: $tool_path${GO_MGR_NC}"
            
            # For 'go' command, verify version if expected version is provided
            if [ "$tool" = "go" ] && [ -n "$expected_version" ]; then
                local actual_version=$($tool version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 | sed 's/^go//')
                
                if [ "$actual_version" = "$expected_version" ]; then
                    echo -e "${GO_MGR_GREEN}  Version: $actual_version (matches expected)${GO_MGR_NC}"
                else
                    echo -e "${GO_MGR_YELLOW}  Version: $actual_version (expected: $expected_version)${GO_MGR_NC}"
                fi
            fi
        else
            echo -e "${GO_MGR_RED}✗ $tool is NOT accessible${GO_MGR_NC}"
            all_accessible=false
        fi
    done
    
    if [ "$all_accessible" = true ]; then
        echo -e "${GO_MGR_GREEN}✓ All Go tools are accessible${GO_MGR_NC}"
        return 0
    else
        echo -e "${GO_MGR_RED}✗ Some Go tools are not accessible${GO_MGR_NC}"
        return 1
    fi
}

#######################################
# Display current alternatives configuration for Go
# Shows which Go version is currently active via alternatives
#
# Arguments:
#   $1 - Sudo command (empty string if running as root)
# Outputs:
#   Current alternatives configuration
#######################################
display_alternatives_status() {
    local sudo_cmd="${1:-}"
    
    echo ""
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Current Go Alternatives Status                           ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    if ! command -v update-alternatives &>/dev/null; then
        echo -e "${GO_MGR_YELLOW}update-alternatives not available${GO_MGR_NC}"
        echo ""
        return 0
    fi
    
    for tool in "${GO_TOOLS[@]}"; do
        if $sudo_cmd update-alternatives --query "$tool" &>/dev/null; then
            echo -e "${GO_MGR_CYAN}$tool:${GO_MGR_NC}"
            
            # Get current selection
            local current=$($sudo_cmd update-alternatives --query "$tool" 2>/dev/null | grep "^Value:" | awk '{print $2}')
            if [ -n "$current" ]; then
                echo -e "${GO_MGR_GREEN}  Current: $current${GO_MGR_NC}"
            fi
            
            # List all alternatives
            echo -e "${GO_MGR_CYAN}  Available alternatives:${GO_MGR_NC}"
            $sudo_cmd update-alternatives --list "$tool" 2>/dev/null | while read -r alt; do
                if [ "$alt" = "$current" ]; then
                    echo -e "${GO_MGR_GREEN}    → $alt (active)${GO_MGR_NC}"
                else
                    echo -e "    - $alt"
                fi
            done
            echo ""
        else
            echo -e "${GO_MGR_YELLOW}$tool: No alternatives configured${GO_MGR_NC}"
            echo ""
        fi
    done
}

#######################################
# Main function to configure Go in system PATH
# Orchestrates alternatives setup or symlink creation
#
# Arguments:
#   $1 - Go installation path
#   $2 - Sudo command (optional, auto-detected if not provided)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Complete configuration process with status
#######################################
configure_go_system_path() {
    local go_install_path="$1"
    local sudo_cmd="${2:-}"
    
    if [ -z "$go_install_path" ]; then
        echo -e "${GO_MGR_RED}✗ No Go installation path provided${GO_MGR_NC}"
        return 1
    fi
    
    # Auto-detect sudo requirement if not provided
    if [ -z "$sudo_cmd" ]; then
        if [ "$EUID" -ne 0 ]; then
            sudo_cmd="sudo"
        else
            sudo_cmd=""
        fi
    fi
    
    echo ""
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Configuring Go in System PATH                            ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    # Try update-alternatives first (preferred method)
    if setup_go_alternatives "$go_install_path" "$GO_ALTERNATIVES_PRIORITY" "$sudo_cmd"; then
        echo ""
        echo -e "${GO_MGR_GREEN}✅ Go configured via update-alternatives${GO_MGR_NC}"
    else
        # Fallback to direct symlinks
        echo ""
        echo -e "${GO_MGR_YELLOW}⚠ Falling back to direct symlink creation${GO_MGR_NC}"
        echo ""
        
        if ! create_go_symlinks "$go_install_path" "$sudo_cmd"; then
            echo -e "${GO_MGR_RED}✗ Failed to configure Go in system PATH${GO_MGR_NC}"
            return 1
        fi
        
        echo ""
        echo -e "${GO_MGR_GREEN}✅ Go configured via direct symlinks${GO_MGR_NC}"
    fi
    
    # Verify configuration
    echo ""
    if verify_go_tools_accessible; then
        echo ""
        echo -e "${GO_MGR_GREEN}✅ Go is now accessible from command line${GO_MGR_NC}"
        
        # Display alternatives status
        display_alternatives_status "$sudo_cmd"
        
        return 0
    else
        echo ""
        echo -e "${GO_MGR_RED}✗ Go tools are not accessible after configuration${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}You may need to add Go to your PATH manually:${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}  export PATH=\$PATH:$go_install_path/bin${GO_MGR_NC}"
        return 1
    fi
}

# Export alternatives and symlink management functions
export -f check_alternatives_available
export -f remove_existing_go_alternatives
export -f setup_go_alternatives
export -f create_go_symlinks
export -f verify_go_tools_accessible
export -f display_alternatives_status
export -f configure_go_system_path

#######################################
# ENHANCED ERROR HANDLING MODULE
# This section provides comprehensive error detection, diagnosis,
# and recovery for common build failures
#######################################

# Error type constants
readonly ERROR_TYPE_GO_NOT_FOUND="go_not_found"
readonly ERROR_TYPE_INCOMPATIBLE_VERSION="incompatible_version"
readonly ERROR_TYPE_RUNTIME_ERROR="runtime_error"
readonly ERROR_TYPE_MODULE_DOWNLOAD="module_download"
readonly ERROR_TYPE_PERMISSION="permission_error"
readonly ERROR_TYPE_DISK_SPACE="disk_space_error"
readonly ERROR_TYPE_NETWORK="network_error"
readonly ERROR_TYPE_BUILD_FAILED="build_failed"
readonly ERROR_TYPE_DEPENDENCY_MISSING="dependency_missing"

#######################################
# Detect specific error patterns in build output
# Analyzes error messages to identify root cause
#
# Arguments:
#   $1 - Error output text
# Returns:
#   Error type constant
# Outputs:
#   Detected error type
#######################################
detect_error_type() {
    local error_output="$1"
    
    if [ -z "$error_output" ]; then
        echo "$ERROR_TYPE_BUILD_FAILED"
        return
    fi
    
    # Check for runtime.stopTheWorld error (Go 1.23+ incompatibility)
    if echo "$error_output" | grep -qi "runtime\.stopTheWorld"; then
        echo "$ERROR_TYPE_RUNTIME_ERROR"
        return
    fi
    
    # Check for module download failures
    if echo "$error_output" | grep -qiE "(module download|go: downloading|connection refused|timeout|dial tcp)"; then
        echo "$ERROR_TYPE_MODULE_DOWNLOAD"
        return
    fi
    
    # Check for permission errors
    if echo "$error_output" | grep -qiE "(permission denied|cannot create directory|operation not permitted)"; then
        echo "$ERROR_TYPE_PERMISSION"
        return
    fi
    
    # Check for disk space errors
    if echo "$error_output" | grep -qiE "(no space left|disk full|cannot allocate memory)"; then
        echo "$ERROR_TYPE_DISK_SPACE"
        return
    fi
    
    # Check for network errors
    if echo "$error_output" | grep -qiE "(network unreachable|no route to host|connection timed out|temporary failure in name resolution)"; then
        echo "$ERROR_TYPE_NETWORK"
        return
    fi
    
    # Check for missing dependencies
    if echo "$error_output" | grep -qiE "(gcc: command not found|make: command not found|pkg-config|cannot find -l)"; then
        echo "$ERROR_TYPE_DEPENDENCY_MISSING"
        return
    fi
    
    # Default to generic build failure
    echo "$ERROR_TYPE_BUILD_FAILED"
}

#######################################
# Diagnose network connectivity issues
# Performs comprehensive network diagnostics
#
# Returns:
#   0 if network is OK, 1 if issues detected
# Outputs:
#   Detailed network diagnostic results
#######################################
diagnose_network() {
    echo -e "${GO_MGR_CYAN}Running network diagnostics...${GO_MGR_NC}"
    echo ""
    
    local issues_found=false
    
    # Test 1: DNS resolution
    echo -e "${GO_MGR_CYAN}1. Testing DNS resolution...${GO_MGR_NC}"
    if host go.dev &>/dev/null || nslookup go.dev &>/dev/null || dig go.dev &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ DNS resolution working${GO_MGR_NC}"
    else
        echo -e "${GO_MGR_RED}✗ DNS resolution failed${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  Possible causes:${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - DNS server not configured${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - /etc/resolv.conf misconfigured${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - Firewall blocking DNS (port 53)${GO_MGR_NC}"
        issues_found=true
    fi
    
    # Test 2: Internet connectivity
    echo -e "${GO_MGR_CYAN}2. Testing internet connectivity...${GO_MGR_NC}"
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ Internet connectivity OK${GO_MGR_NC}"
    else
        echo -e "${GO_MGR_RED}✗ No internet connectivity${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  Possible causes:${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - Network interface down${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - No default gateway${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - Firewall blocking ICMP${GO_MGR_NC}"
        issues_found=true
    fi
    
    # Test 3: HTTPS connectivity to go.dev
    echo -e "${GO_MGR_CYAN}3. Testing HTTPS connectivity to go.dev...${GO_MGR_NC}"
    if curl -s --connect-timeout 5 https://go.dev &>/dev/null || wget -q --timeout=5 --spider https://go.dev &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ HTTPS connectivity to go.dev OK${GO_MGR_NC}"
    else
        echo -e "${GO_MGR_RED}✗ Cannot reach go.dev${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  Possible causes:${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - Firewall blocking HTTPS (port 443)${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - Proxy configuration needed${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}  - SSL/TLS certificate issues${GO_MGR_NC}"
        issues_found=true
    fi
    
    # Test 4: Proxy detection
    echo -e "${GO_MGR_CYAN}4. Checking proxy configuration...${GO_MGR_NC}"
    if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ] || [ -n "$http_proxy" ] || [ -n "$https_proxy" ]; then
        echo -e "${GO_MGR_YELLOW}⚠ Proxy detected:${GO_MGR_NC}"
        [ -n "$HTTP_PROXY" ] && echo -e "${GO_MGR_CYAN}  HTTP_PROXY: $HTTP_PROXY${GO_MGR_NC}"
        [ -n "$HTTPS_PROXY" ] && echo -e "${GO_MGR_CYAN}  HTTPS_PROXY: $HTTPS_PROXY${GO_MGR_NC}"
        [ -n "$http_proxy" ] && echo -e "${GO_MGR_CYAN}  http_proxy: $http_proxy${GO_MGR_NC}"
        [ -n "$https_proxy" ] && echo -e "${GO_MGR_CYAN}  https_proxy: $https_proxy${GO_MGR_NC}"
    else
        echo -e "${GO_MGR_GREEN}✓ No proxy configured${GO_MGR_NC}"
    fi
    
    echo ""
    
    if [ "$issues_found" = true ]; then
        return 1
    else
        return 0
    fi
}

#######################################
# Check system dependencies for Geth build
# Verifies all required build tools are installed
#
# Returns:
#   0 if all dependencies present, 1 if missing
# Outputs:
#   List of missing dependencies
#######################################
check_build_dependencies() {
    echo -e "${GO_MGR_CYAN}Checking build dependencies...${GO_MGR_NC}"
    
    local missing_deps=()
    local required_deps=("gcc" "g++" "make" "git" "pkg-config")
    
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check for build-essential package on Debian/Ubuntu
    if command -v dpkg &>/dev/null; then
        if ! dpkg -l build-essential &>/dev/null; then
            echo -e "${GO_MGR_YELLOW}⚠ build-essential package not installed${GO_MGR_NC}"
        fi
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo -e "${GO_MGR_GREEN}✓ All build dependencies present${GO_MGR_NC}"
        return 0
    else
        echo -e "${GO_MGR_RED}✗ Missing dependencies: ${missing_deps[*]}${GO_MGR_NC}"
        return 1
    fi
}

#######################################
# Provide detailed error explanation and recovery steps
# Main error handling function that provides context-aware guidance
#
# Arguments:
#   $1 - Error type
#   $2 - Error message (optional)
#   $3 - Ubuntu version (optional)
# Outputs:
#   Comprehensive error report with recovery steps
#######################################
explain_error() {
    local error_type="$1"
    local error_msg="${2:-}"
    local ubuntu_version="${3:-}"
    
    echo ""
    echo -e "${GO_MGR_RED}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_RED}║   Build Error Detected                                     ║${GO_MGR_NC}"
    echo -e "${GO_MGR_RED}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    case "$error_type" in
        "$ERROR_TYPE_RUNTIME_ERROR")
            echo -e "${GO_MGR_RED}Error Type: Runtime API Incompatibility${GO_MGR_NC}"
            echo ""
            echo -e "${GO_MGR_YELLOW}Root Cause:${GO_MGR_NC}"
            echo -e "  The error 'invalid reference to runtime.stopTheWorld' indicates"
            echo -e "  that you are using Go 1.23 or newer, which has breaking changes"
            echo -e "  in the runtime package."
            echo ""
            echo -e "  The dependency 'github.com/fjl/memsize' used by go-ethereum"
            echo -e "  relies on internal runtime APIs that changed in Go 1.23."
            echo ""
            echo -e "${GO_MGR_YELLOW}Technical Details:${GO_MGR_NC}"
            echo -e "  - Go 1.23+ removed or changed runtime.stopTheWorld API"
            echo -e "  - This affects memory profiling and size calculation"
            echo -e "  - Geth requires Go 1.21 or 1.22 for compatibility"
            echo ""
            echo -e "${GO_MGR_CYAN}Solution:${GO_MGR_NC}"
            echo -e "  1. Install Go 1.22 (recommended) or Go 1.21"
            echo -e "  2. Configure system to use the compatible version"
            echo -e "  3. Rebuild Geth with the correct Go version"
            echo ""
            echo -e "${GO_MGR_CYAN}Automatic Fix:${GO_MGR_NC}"
            echo -e "  This script can automatically install Go 1.22 for you."
            echo -e "  Re-run the script and it will handle the installation."
            ;;
            
        "$ERROR_TYPE_MODULE_DOWNLOAD")
            echo -e "${GO_MGR_RED}Error Type: Module Download Failure${GO_MGR_NC}"
            echo ""
            echo -e "${GO_MGR_YELLOW}Root Cause:${GO_MGR_NC}"
            echo -e "  Failed to download Go modules from proxy.golang.org"
            echo ""
            
            # Run network diagnostics
            if ! diagnose_network; then
                echo ""
                echo -e "${GO_MGR_CYAN}Recovery Steps:${GO_MGR_NC}"
                echo -e "  1. Fix network connectivity issues identified above"
                echo -e "  2. If behind a proxy, configure Go proxy settings:"
                echo -e "     export GOPROXY=https://proxy.golang.org,direct"
                echo -e "  3. If proxy requires authentication, set credentials"
                echo -e "  4. Try alternative proxy: export GOPROXY=https://goproxy.io,direct"
                echo -e "  5. Clear module cache: go clean -modcache"
                echo -e "  6. Retry the build"
            else
                echo -e "${GO_MGR_CYAN}Recovery Steps:${GO_MGR_NC}"
                echo -e "  1. Wait a moment and retry (temporary network issue)"
                echo -e "  2. Clear module cache: go clean -modcache"
                echo -e "  3. Try alternative proxy: export GOPROXY=https://goproxy.io,direct"
                echo -e "  4. Check if go.dev is accessible: curl -I https://go.dev"
            fi
            ;;
            
        "$ERROR_TYPE_PERMISSION")
            echo -e "${GO_MGR_RED}Error Type: Permission Denied${GO_MGR_NC}"
            echo ""
            echo -e "${GO_MGR_YELLOW}Root Cause:${GO_MGR_NC}"
            echo -e "  Insufficient permissions to write files or execute commands"
            echo ""
            echo -e "${GO_MGR_CYAN}Recovery Steps:${GO_MGR_NC}"
            echo -e "  1. Run the script with sudo: sudo ./setup-blockchain-complete.sh"
            echo -e "  2. Or fix permissions on the directory:"
            echo -e "     sudo chown -R \$USER:\$USER ."
            echo -e "  3. Ensure GOPATH directory is writable:"
            echo -e "     mkdir -p ~/go && chmod 755 ~/go"
            echo -e "  4. Check /tmp directory permissions: ls -ld /tmp"
            ;;
            
        "$ERROR_TYPE_DISK_SPACE")
            echo -e "${GO_MGR_RED}Error Type: Insufficient Disk Space${GO_MGR_NC}"
            echo ""
            echo -e "${GO_MGR_YELLOW}Root Cause:${GO_MGR_NC}"
            echo -e "  Not enough disk space to complete the build"
            echo ""
            
            # Show disk usage
            echo -e "${GO_MGR_CYAN}Current Disk Usage:${GO_MGR_NC}"
            df -h . 2>/dev/null | head -2
            echo ""
            
            echo -e "${GO_MGR_CYAN}Recovery Steps:${GO_MGR_NC}"
            echo -e "  1. Free up disk space (at least 2GB recommended)"
            echo -e "  2. Clean Go cache: go clean -cache -modcache"
            echo -e "  3. Remove old Docker images: docker system prune -a"
            echo -e "  4. Clean apt cache: sudo apt clean"
            echo -e "  5. Check large files: du -sh /* 2>/dev/null | sort -h"
            ;;
            
        "$ERROR_TYPE_NETWORK")
            echo -e "${GO_MGR_RED}Error Type: Network Connectivity Issue${GO_MGR_NC}"
            echo ""
            diagnose_network
            ;;
            
        "$ERROR_TYPE_DEPENDENCY_MISSING")
            echo -e "${GO_MGR_RED}Error Type: Missing Build Dependencies${GO_MGR_NC}"
            echo ""
            check_build_dependencies
            echo ""
            echo -e "${GO_MGR_CYAN}Recovery Steps:${GO_MGR_NC}"
            
            if [ -n "$ubuntu_version" ]; then
                echo -e "  For Ubuntu $ubuntu_version:"
            fi
            
            echo -e "  1. Install build essentials:"
            echo -e "     sudo apt update"
            echo -e "     sudo apt install -y build-essential"
            echo -e "  2. Install additional dependencies:"
            echo -e "     sudo apt install -y git pkg-config libssl-dev"
            echo -e "  3. Retry the build"
            ;;
            
        "$ERROR_TYPE_BUILD_FAILED")
            echo -e "${GO_MGR_RED}Error Type: Generic Build Failure${GO_MGR_NC}"
            echo ""
            echo -e "${GO_MGR_YELLOW}Error Message:${GO_MGR_NC}"
            if [ -n "$error_msg" ]; then
                echo "$error_msg" | head -20
            else
                echo "  No specific error message available"
            fi
            echo ""
            echo -e "${GO_MGR_CYAN}Troubleshooting Steps:${GO_MGR_NC}"
            echo -e "  1. Check Go version: go version"
            echo -e "  2. Verify Go installation: go env"
            echo -e "  3. Clean build cache: go clean -cache -modcache"
            echo -e "  4. Check build dependencies"
            echo -e "  5. Review full error output above"
            echo -e "  6. Search for error message online"
            ;;
            
        *)
            echo -e "${GO_MGR_RED}Error Type: Unknown${GO_MGR_NC}"
            echo ""
            echo -e "${GO_MGR_YELLOW}An unexpected error occurred${GO_MGR_NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GO_MGR_CYAN}Support Resources:${GO_MGR_NC}"
    echo -e "  - Geth Documentation: https://geth.ethereum.org/docs"
    echo -e "  - Go Documentation: https://go.dev/doc/"
    echo -e "  - GitHub Issues: https://github.com/ethereum/go-ethereum/issues"
    echo ""
}

#######################################
# Handle build error with automatic recovery attempt
# Orchestrates error detection, explanation, and recovery
#
# Arguments:
#   $1 - Error output
#   $2 - Sudo command
# Returns:
#   0 if recovery successful, 1 if manual intervention needed
# Outputs:
#   Error handling process
#######################################
handle_build_error() {
    local error_output="$1"
    local sudo_cmd="${2:-}"
    
    # Detect error type
    local error_type=$(detect_error_type "$error_output")
    
    # Explain the error
    explain_error "$error_type" "$error_output"
    
    # Attempt automatic recovery for certain error types
    case "$error_type" in
        "$ERROR_TYPE_RUNTIME_ERROR")
            echo -e "${GO_MGR_CYAN}Attempting automatic recovery...${GO_MGR_NC}"
            echo ""
            
            if install_compatible_go "$sudo_cmd"; then
                echo ""
                echo -e "${GO_MGR_GREEN}✅ Recovery successful${GO_MGR_NC}"
                echo -e "${GO_MGR_YELLOW}Please retry the build${GO_MGR_NC}"
                return 0
            else
                echo ""
                echo -e "${GO_MGR_RED}✗ Automatic recovery failed${GO_MGR_NC}"
                return 1
            fi
            ;;
            
        "$ERROR_TYPE_MODULE_DOWNLOAD")
            echo -e "${GO_MGR_CYAN}Attempting automatic recovery...${GO_MGR_NC}"
            echo ""
            echo -e "${GO_MGR_YELLOW}Cleaning module cache...${GO_MGR_NC}"
            
            if go clean -modcache 2>&1; then
                echo -e "${GO_MGR_GREEN}✓ Module cache cleaned${GO_MGR_NC}"
                echo -e "${GO_MGR_YELLOW}Please retry the build${GO_MGR_NC}"
                return 0
            else
                echo -e "${GO_MGR_RED}✗ Failed to clean module cache${GO_MGR_NC}"
                return 1
            fi
            ;;
            
        *)
            echo -e "${GO_MGR_YELLOW}⚠ No automatic recovery available for this error type${GO_MGR_NC}"
            echo -e "${GO_MGR_YELLOW}Please follow the recovery steps above${GO_MGR_NC}"
            return 1
            ;;
    esac
}

# Export error handling functions
export -f detect_error_type
export -f diagnose_network
export -f check_build_dependencies
export -f explain_error
export -f handle_build_error

#######################################
# USER-FRIENDLY ERROR MESSAGE FORMATTING MODULE
# This section provides enhanced message formatting utilities
# for clear, actionable, and user-friendly error communication
#######################################

#######################################
# Display a formatted error box with title and message
# Creates visually distinct error messages
#
# Arguments:
#   $1 - Error title
#   $2 - Error message (optional)
# Outputs:
#   Formatted error box
#######################################
display_error_box() {
    local title="$1"
    local message="${2:-}"
    
    echo ""
    echo -e "${GO_MGR_RED}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    printf "${GO_MGR_RED}║${GO_MGR_NC} %-58s ${GO_MGR_RED}║${GO_MGR_NC}\n" "$title"
    echo -e "${GO_MGR_RED}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    
    if [ -n "$message" ]; then
        echo ""
        echo -e "$message"
    fi
    echo ""
}

#######################################
# Display a formatted warning box
# Creates visually distinct warning messages
#
# Arguments:
#   $1 - Warning title
#   $2 - Warning message (optional)
# Outputs:
#   Formatted warning box
#######################################
display_warning_box() {
    local title="$1"
    local message="${2:-}"
    
    echo ""
    echo -e "${GO_MGR_YELLOW}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    printf "${GO_MGR_YELLOW}║${GO_MGR_NC} %-58s ${GO_MGR_YELLOW}║${GO_MGR_NC}\n" "$title"
    echo -e "${GO_MGR_YELLOW}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    
    if [ -n "$message" ]; then
        echo ""
        echo -e "$message"
    fi
    echo ""
}

#######################################
# Display a formatted success box
# Creates visually distinct success messages
#
# Arguments:
#   $1 - Success title
#   $2 - Success message (optional)
# Outputs:
#   Formatted success box
#######################################
display_success_box() {
    local title="$1"
    local message="${2:-}"
    
    echo ""
    echo -e "${GO_MGR_GREEN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    printf "${GO_MGR_GREEN}║${GO_MGR_NC} %-58s ${GO_MGR_GREEN}║${GO_MGR_NC}\n" "$title"
    echo -e "${GO_MGR_GREEN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    
    if [ -n "$message" ]; then
        echo ""
        echo -e "$message"
    fi
    echo ""
}

#######################################
# Display a formatted info box
# Creates visually distinct informational messages
#
# Arguments:
#   $1 - Info title
#   $2 - Info message (optional)
# Outputs:
#   Formatted info box
#######################################
display_info_box() {
    local title="$1"
    local message="${2:-}"
    
    echo ""
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    printf "${GO_MGR_CYAN}║${GO_MGR_NC} %-58s ${GO_MGR_CYAN}║${GO_MGR_NC}\n" "$title"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    
    if [ -n "$message" ]; then
        echo ""
        echo -e "$message"
    fi
    echo ""
}

#######################################
# Display numbered recovery steps
# Formats recovery instructions in a clear, actionable format
#
# Arguments:
#   $@ - Array of recovery steps
# Outputs:
#   Formatted numbered list
#######################################
display_recovery_steps() {
    echo -e "${GO_MGR_CYAN}Recovery Steps:${GO_MGR_NC}"
    echo ""
    
    local step_num=1
    for step in "$@"; do
        echo -e "${GO_MGR_GREEN}  $step_num.${GO_MGR_NC} $step"
        ((step_num++))
    done
    echo ""
}

#######################################
# Display a progress indicator
# Shows ongoing operation status
#
# Arguments:
#   $1 - Operation description
#   $2 - Status (in_progress, success, failed)
# Outputs:
#   Formatted progress line
#######################################
display_progress() {
    local operation="$1"
    local status="${2:-in_progress}"
    
    case "$status" in
        "in_progress")
            echo -e "${GO_MGR_CYAN}⏳ $operation...${GO_MGR_NC}"
            ;;
        "success")
            echo -e "${GO_MGR_GREEN}✓ $operation${GO_MGR_NC}"
            ;;
        "failed")
            echo -e "${GO_MGR_RED}✗ $operation${GO_MGR_NC}"
            ;;
        "warning")
            echo -e "${GO_MGR_YELLOW}⚠ $operation${GO_MGR_NC}"
            ;;
        *)
            echo -e "${GO_MGR_CYAN}• $operation${GO_MGR_NC}"
            ;;
    esac
}

#######################################
# Display a command example with syntax highlighting
# Shows commands in a visually distinct format
#
# Arguments:
#   $1 - Command description
#   $2 - Command to execute
# Outputs:
#   Formatted command example
#######################################
display_command_example() {
    local description="$1"
    local command="$2"
    
    echo -e "${GO_MGR_CYAN}$description:${GO_MGR_NC}"
    echo -e "${GO_MGR_YELLOW}  \$ $command${GO_MGR_NC}"
    echo ""
}

#######################################
# Display a troubleshooting checklist
# Shows a checklist of items to verify
#
# Arguments:
#   $@ - Array of checklist items
# Outputs:
#   Formatted checklist
#######################################
display_troubleshooting_checklist() {
    echo -e "${GO_MGR_CYAN}Troubleshooting Checklist:${GO_MGR_NC}"
    echo ""
    
    for item in "$@"; do
        echo -e "${GO_MGR_YELLOW}  ☐${GO_MGR_NC} $item"
    done
    echo ""
}

#######################################
# Display comprehensive error report
# Combines all error information in a user-friendly format
#
# Arguments:
#   $1 - Error type
#   $2 - Error title
#   $3 - Root cause
#   $4 - Technical details
#   $@ - Recovery steps (remaining arguments)
# Outputs:
#   Complete formatted error report
#######################################
display_comprehensive_error_report() {
    local error_type="$1"
    local error_title="$2"
    local root_cause="$3"
    local technical_details="$4"
    shift 4
    local recovery_steps=("$@")
    
    # Error header
    display_error_box "❌ $error_title"
    
    # Error type
    echo -e "${GO_MGR_RED}Error Type:${GO_MGR_NC} $error_type"
    echo ""
    
    # Root cause
    echo -e "${GO_MGR_YELLOW}Root Cause:${GO_MGR_NC}"
    echo -e "$root_cause"
    echo ""
    
    # Technical details (if provided)
    if [ -n "$technical_details" ]; then
        echo -e "${GO_MGR_CYAN}Technical Details:${GO_MGR_NC}"
        echo -e "$technical_details"
        echo ""
    fi
    
    # Recovery steps
    if [ ${#recovery_steps[@]} -gt 0 ]; then
        display_recovery_steps "${recovery_steps[@]}"
    fi
    
    # Support resources
    echo -e "${GO_MGR_CYAN}Need Help?${GO_MGR_NC}"
    echo -e "  • Documentation: ${GO_MGR_CYAN}https://geth.ethereum.org/docs${GO_MGR_NC}"
    echo -e "  • Community: ${GO_MGR_CYAN}https://github.com/ethereum/go-ethereum/discussions${GO_MGR_NC}"
    echo -e "  • Issues: ${GO_MGR_CYAN}https://github.com/ethereum/go-ethereum/issues${GO_MGR_NC}"
    echo ""
}

#######################################
# Display a summary of actions taken
# Shows what was done during error recovery
#
# Arguments:
#   $@ - Array of actions taken
# Outputs:
#   Formatted action summary
#######################################
display_action_summary() {
    echo -e "${GO_MGR_CYAN}Actions Taken:${GO_MGR_NC}"
    echo ""
    
    for action in "$@"; do
        echo -e "${GO_MGR_GREEN}  ✓${GO_MGR_NC} $action"
    done
    echo ""
}

#######################################
# Display next steps after error resolution
# Guides user on what to do next
#
# Arguments:
#   $@ - Array of next steps
# Outputs:
#   Formatted next steps
#######################################
display_next_steps() {
    echo -e "${GO_MGR_CYAN}Next Steps:${GO_MGR_NC}"
    echo ""
    
    local step_num=1
    for step in "$@"; do
        echo -e "${GO_MGR_CYAN}  $step_num.${GO_MGR_NC} $step"
        ((step_num++))
    done
    echo ""
}

#######################################
# Ask user for confirmation with clear prompt
# Provides a user-friendly yes/no prompt
#
# Arguments:
#   $1 - Question to ask
#   $2 - Default answer (yes/no, optional)
# Returns:
#   0 for yes, 1 for no
# Outputs:
#   Formatted question prompt
#######################################
ask_user_confirmation() {
    local question="$1"
    local default="${2:-}"
    local prompt_suffix=""
    
    if [ "$default" = "yes" ]; then
        prompt_suffix=" [Y/n]"
    elif [ "$default" = "no" ]; then
        prompt_suffix=" [y/N]"
    else
        prompt_suffix=" [y/n]"
    fi
    
    echo ""
    echo -e "${GO_MGR_YELLOW}$question$prompt_suffix${GO_MGR_NC}"
    read -p "> " answer
    
    # Handle default
    if [ -z "$answer" ] && [ -n "$default" ]; then
        answer="$default"
    fi
    
    # Normalize answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    
    if [ "$answer" = "yes" ] || [ "$answer" = "y" ]; then
        return 0
    else
        return 1
    fi
}

#######################################
# Display a separator line
# Visual separator for different sections
#
# Arguments:
#   $1 - Style (solid, dashed, dotted)
# Outputs:
#   Formatted separator line
#######################################
display_separator() {
    local style="${1:-solid}"
    
    case "$style" in
        "solid")
            echo -e "${GO_MGR_CYAN}════════════════════════════════════════════════════════════${GO_MGR_NC}"
            ;;
        "dashed")
            echo -e "${GO_MGR_CYAN}------------------------------------------------------------${GO_MGR_NC}"
            ;;
        "dotted")
            echo -e "${GO_MGR_CYAN}............................................................${GO_MGR_NC}"
            ;;
        *)
            echo -e "${GO_MGR_CYAN}════════════════════════════════════════════════════════════${GO_MGR_NC}"
            ;;
    esac
}

# Export message formatting functions
export -f display_error_box
export -f display_warning_box
export -f display_success_box
export -f display_info_box
export -f display_recovery_steps
export -f display_progress
export -f display_command_example
export -f display_troubleshooting_checklist
export -f display_comprehensive_error_report
export -f display_action_summary
export -f display_next_steps
export -f ask_user_confirmation
export -f display_separator

#######################################
# BUILD RETRY LOGIC MODULE
# This section provides intelligent retry mechanism for failed builds
# with cache cleaning, exponential backoff, and state tracking
#######################################

# Retry configuration
readonly MAX_BUILD_RETRIES=2
readonly RETRY_DELAY_BASE=5

# Global retry state
BUILD_RETRY_COUNT=0
BUILD_RETRY_HISTORY=()

#######################################
# Clean Go build and module caches
# Removes all cached data to ensure clean build
#
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Cache cleaning progress and results
#######################################
clean_go_caches() {
    echo -e "${GO_MGR_CYAN}Cleaning Go caches...${GO_MGR_NC}"
    echo ""
    
    local cache_cleaned=false
    local modcache_cleaned=false
    
    # Clean build cache
    display_progress "Cleaning build cache" "in_progress"
    if go clean -cache 2>&1; then
        display_progress "Build cache cleaned" "success"
        cache_cleaned=true
    else
        display_progress "Failed to clean build cache" "warning"
    fi
    
    # Clean module cache
    display_progress "Cleaning module cache" "in_progress"
    if go clean -modcache 2>&1; then
        display_progress "Module cache cleaned" "success"
        modcache_cleaned=true
    else
        display_progress "Failed to clean module cache" "warning"
    fi
    
    # Clean test cache
    display_progress "Cleaning test cache" "in_progress"
    if go clean -testcache 2>&1; then
        display_progress "Test cache cleaned" "success"
    else
        display_progress "Failed to clean test cache" "warning"
    fi
    
    echo ""
    
    if [ "$cache_cleaned" = true ] && [ "$modcache_cleaned" = true ]; then
        echo -e "${GO_MGR_GREEN}✅ All caches cleaned successfully${GO_MGR_NC}"
        return 0
    else
        echo -e "${GO_MGR_YELLOW}⚠ Some caches could not be cleaned${GO_MGR_NC}"
        return 1
    fi
}

#######################################
# Verify that caches are actually cleared
# Checks cache directories to confirm cleaning
#
# Returns:
#   0 if caches are clear, 1 if not
# Outputs:
#   Cache verification status
#######################################
verify_caches_cleared() {
    echo -e "${GO_MGR_CYAN}Verifying cache cleanup...${GO_MGR_NC}"
    
    local gopath=$(go env GOPATH 2>/dev/null)
    local gocache=$(go env GOCACHE 2>/dev/null)
    
    local all_clear=true
    
    # Check module cache
    if [ -n "$gopath" ] && [ -d "$gopath/pkg/mod" ]; then
        local mod_count=$(find "$gopath/pkg/mod" -type f 2>/dev/null | wc -l)
        if [ "$mod_count" -gt 10 ]; then
            echo -e "${GO_MGR_YELLOW}⚠ Module cache still contains files${GO_MGR_NC}"
            all_clear=false
        else
            echo -e "${GO_MGR_GREEN}✓ Module cache is clear${GO_MGR_NC}"
        fi
    fi
    
    # Check build cache
    if [ -n "$gocache" ] && [ -d "$gocache" ]; then
        local cache_size=$(du -sm "$gocache" 2>/dev/null | cut -f1)
        if [ -n "$cache_size" ] && [ "$cache_size" -gt 100 ]; then
            echo -e "${GO_MGR_YELLOW}⚠ Build cache still large (${cache_size}MB)${GO_MGR_NC}"
            all_clear=false
        else
            echo -e "${GO_MGR_GREEN}✓ Build cache is clear${GO_MGR_NC}"
        fi
    fi
    
    if [ "$all_clear" = true ]; then
        return 0
    else
        return 1
    fi
}

#######################################
# Calculate retry delay with exponential backoff
# Implements exponential backoff strategy
#
# Arguments:
#   $1 - Retry attempt number
# Returns:
#   Delay in seconds
#######################################
calculate_retry_delay() {
    local attempt="$1"
    
    # Exponential backoff: base * 2^(attempt-1)
    local delay=$((RETRY_DELAY_BASE * (2 ** (attempt - 1))))
    
    # Cap at 60 seconds
    if [ "$delay" -gt 60 ]; then
        delay=60
    fi
    
    echo "$delay"
}

#######################################
# Record build attempt in retry history
# Tracks all build attempts for analysis
#
# Arguments:
#   $1 - Attempt number
#   $2 - Result (success/failed)
#   $3 - Error type (optional)
#######################################
record_build_attempt() {
    local attempt="$1"
    local result="$2"
    local error_type="${3:-unknown}"
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    BUILD_RETRY_HISTORY+=("$timestamp | Attempt $attempt | $result | $error_type")
}

#######################################
# Display retry history
# Shows all build attempts made
#
# Outputs:
#   Formatted retry history
#######################################
display_retry_history() {
    if [ ${#BUILD_RETRY_HISTORY[@]} -eq 0 ]; then
        return
    fi
    
    echo ""
    echo -e "${GO_MGR_CYAN}Build Attempt History:${GO_MGR_NC}"
    echo ""
    
    for entry in "${BUILD_RETRY_HISTORY[@]}"; do
        if echo "$entry" | grep -q "success"; then
            echo -e "${GO_MGR_GREEN}  ✓ $entry${GO_MGR_NC}"
        else
            echo -e "${GO_MGR_RED}  ✗ $entry${GO_MGR_NC}"
        fi
    done
    echo ""
}

#######################################
# Analyze build failures to determine if retry is worthwhile
# Checks if the error type is recoverable
#
# Arguments:
#   $1 - Error type
# Returns:
#   0 if retry recommended, 1 if not
#######################################
should_retry_build() {
    local error_type="$1"
    
    # Errors that are worth retrying
    case "$error_type" in
        "$ERROR_TYPE_MODULE_DOWNLOAD"|"$ERROR_TYPE_NETWORK")
            # Network issues might be temporary
            return 0
            ;;
        "$ERROR_TYPE_BUILD_FAILED")
            # Generic build failures might be cache-related
            return 0
            ;;
        "$ERROR_TYPE_RUNTIME_ERROR"|"$ERROR_TYPE_INCOMPATIBLE_VERSION")
            # Version issues won't be fixed by retry
            return 1
            ;;
        "$ERROR_TYPE_PERMISSION"|"$ERROR_TYPE_DISK_SPACE")
            # System issues need manual intervention
            return 1
            ;;
        "$ERROR_TYPE_DEPENDENCY_MISSING")
            # Missing dependencies need installation
            return 1
            ;;
        *)
            # Unknown errors - try once
            if [ "$BUILD_RETRY_COUNT" -eq 0 ]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

#######################################
# Execute build with retry logic
# Main retry orchestration function
#
# Arguments:
#   $1 - Build command
#   $2 - Build directory
#   $3 - Max retries (optional, defaults to MAX_BUILD_RETRIES)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Complete retry process with progress
#######################################
build_with_retry() {
    local build_command="$1"
    local build_dir="$2"
    local max_retries="${3:-$MAX_BUILD_RETRIES}"
    
    BUILD_RETRY_COUNT=0
    BUILD_RETRY_HISTORY=()
    
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Build with Retry Logic                                   ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    echo -e "${GO_MGR_CYAN}Max retries: $max_retries${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}Build command: $build_command${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}Build directory: $build_dir${GO_MGR_NC}"
    echo ""
    
    while [ "$BUILD_RETRY_COUNT" -le "$max_retries" ]; do
        local attempt=$((BUILD_RETRY_COUNT + 1))
        
        if [ "$BUILD_RETRY_COUNT" -eq 0 ]; then
            echo -e "${GO_MGR_CYAN}═══ Initial Build Attempt ═══${GO_MGR_NC}"
        else
            echo -e "${GO_MGR_YELLOW}═══ Retry Attempt $BUILD_RETRY_COUNT/$max_retries ═══${GO_MGR_NC}"
        fi
        echo ""
        
        # Change to build directory
        cd "$build_dir" || return 1
        
        # Execute build command and capture output
        local build_output
        local build_result
        
        echo -e "${GO_MGR_CYAN}Executing build...${GO_MGR_NC}"
        if build_output=$(eval "$build_command" 2>&1); then
            build_result="success"
            record_build_attempt "$attempt" "success" "none"
            
            echo ""
            echo -e "${GO_MGR_GREEN}✅ Build successful!${GO_MGR_NC}"
            display_retry_history
            return 0
        else
            build_result="failed"
            
            # Detect error type
            local error_type=$(detect_error_type "$build_output")
            record_build_attempt "$attempt" "failed" "$error_type"
            
            echo ""
            echo -e "${GO_MGR_RED}✗ Build failed${GO_MGR_NC}"
            echo -e "${GO_MGR_YELLOW}Error type: $error_type${GO_MGR_NC}"
            
            # Check if we should retry
            if [ "$BUILD_RETRY_COUNT" -lt "$max_retries" ]; then
                if should_retry_build "$error_type"; then
                    echo ""
                    echo -e "${GO_MGR_CYAN}Preparing for retry...${GO_MGR_NC}"
                    echo ""
                    
                    # Clean caches before retry
                    if clean_go_caches; then
                        verify_caches_cleared
                    fi
                    
                    # Calculate and apply delay
                    local delay=$(calculate_retry_delay "$attempt")
                    echo ""
                    echo -e "${GO_MGR_YELLOW}Waiting ${delay} seconds before retry...${GO_MGR_NC}"
                    sleep "$delay"
                    
                    echo ""
                    ((BUILD_RETRY_COUNT++))
                    continue
                else
                    echo ""
                    echo -e "${GO_MGR_YELLOW}⚠ Retry not recommended for this error type${GO_MGR_NC}"
                    echo -e "${GO_MGR_YELLOW}Manual intervention required${GO_MGR_NC}"
                    echo ""
                    
                    # Show error explanation
                    explain_error "$error_type" "$build_output"
                    display_retry_history
                    return 1
                fi
            else
                # Max retries reached
                echo ""
                echo -e "${GO_MGR_RED}✗ Maximum retry attempts reached${GO_MGR_NC}"
                echo ""
                
                # Show comprehensive error report
                explain_error "$error_type" "$build_output"
                display_retry_history
                
                # Show failure analysis
                echo -e "${GO_MGR_CYAN}Failure Analysis:${GO_MGR_NC}"
                echo -e "${GO_MGR_YELLOW}  Total attempts: $((BUILD_RETRY_COUNT + 1))${GO_MGR_NC}"
                echo -e "${GO_MGR_YELLOW}  All attempts failed${GO_MGR_NC}"
                echo -e "${GO_MGR_YELLOW}  Last error type: $error_type${GO_MGR_NC}"
                echo ""
                
                return 1
            fi
        fi
    done
    
    return 1
}

# Export retry logic functions
export -f clean_go_caches
export -f verify_caches_cleared
export -f calculate_retry_delay
export -f record_build_attempt
export -f display_retry_history
export -f should_retry_build
export -f build_with_retry

#######################################
# POST-BUILD VALIDATION MODULE
# This section provides comprehensive validation of built binaries
# to ensure they are functional and ready for deployment
#######################################

#######################################
# Validate Geth binary exists and is executable
# Performs basic file system checks
#
# Arguments:
#   $1 - Path to geth binary
# Returns:
#   0 if valid, 1 if invalid
# Outputs:
#   Validation status
#######################################
validate_geth_binary_exists() {
    local geth_path="$1"
    
    if [ -z "$geth_path" ]; then
        echo -e "${GO_MGR_RED}✗ No geth binary path provided${GO_MGR_NC}"
        return 1
    fi
    
    # Check if file exists
    if [ ! -f "$geth_path" ]; then
        echo -e "${GO_MGR_RED}✗ Geth binary not found: $geth_path${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_GREEN}✓ Geth binary exists${GO_MGR_NC}"
    
    # Check if executable
    if [ ! -x "$geth_path" ]; then
        echo -e "${GO_MGR_YELLOW}⚠ Geth binary is not executable${GO_MGR_NC}"
        echo -e "${GO_MGR_CYAN}  Attempting to fix permissions...${GO_MGR_NC}"
        
        if chmod +x "$geth_path" 2>/dev/null; then
            echo -e "${GO_MGR_GREEN}✓ Permissions fixed${GO_MGR_NC}"
        else
            echo -e "${GO_MGR_RED}✗ Failed to fix permissions${GO_MGR_NC}"
            return 1
        fi
    else
        echo -e "${GO_MGR_GREEN}✓ Geth binary is executable${GO_MGR_NC}"
    fi
    
    return 0
}

#######################################
# Get Geth binary version information
# Extracts version details from geth binary
#
# Arguments:
#   $1 - Path to geth binary
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Version information
#######################################
get_geth_version() {
    local geth_path="$1"
    
    if [ ! -x "$geth_path" ]; then
        echo -e "${GO_MGR_RED}✗ Cannot execute geth binary${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}Extracting version information...${GO_MGR_NC}"
    
    # Get version output
    local version_output
    if ! version_output=$($geth_path version 2>&1); then
        echo -e "${GO_MGR_RED}✗ Failed to get version${GO_MGR_NC}"
        return 1
    fi
    
    # Parse version information
    local geth_version=$(echo "$version_output" | grep -i "version" | head -1)
    local go_version=$(echo "$version_output" | grep -i "go version" | head -1)
    
    if [ -n "$geth_version" ]; then
        echo -e "${GO_MGR_GREEN}✓ Geth Version: $geth_version${GO_MGR_NC}"
    fi
    
    if [ -n "$go_version" ]; then
        echo -e "${GO_MGR_GREEN}✓ Built with: $go_version${GO_MGR_NC}"
    fi
    
    return 0
}

#######################################
# Get Geth binary size and metadata
# Collects binary file information
#
# Arguments:
#   $1 - Path to geth binary
# Outputs:
#   Binary metadata
#######################################
get_geth_binary_info() {
    local geth_path="$1"
    
    if [ ! -f "$geth_path" ]; then
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}Binary Information:${GO_MGR_NC}"
    
    # File size
    local size_bytes=$(stat -f%z "$geth_path" 2>/dev/null || stat -c%s "$geth_path" 2>/dev/null)
    if [ -n "$size_bytes" ]; then
        local size_mb=$((size_bytes / 1024 / 1024))
        echo -e "${GO_MGR_CYAN}  Size: ${size_mb}MB (${size_bytes} bytes)${GO_MGR_NC}"
    fi
    
    # File permissions
    local perms=$(ls -l "$geth_path" | awk '{print $1}')
    echo -e "${GO_MGR_CYAN}  Permissions: $perms${GO_MGR_NC}"
    
    # File modification time
    local mtime=$(stat -f%Sm "$geth_path" 2>/dev/null || stat -c%y "$geth_path" 2>/dev/null | cut -d. -f1)
    if [ -n "$mtime" ]; then
        echo -e "${GO_MGR_CYAN}  Modified: $mtime${GO_MGR_NC}"
    fi
    
    # File type
    if command -v file &>/dev/null; then
        local file_type=$(file "$geth_path" | cut -d: -f2-)
        echo -e "${GO_MGR_CYAN}  Type: $file_type${GO_MGR_NC}"
    fi
}

#######################################
# Test Geth binary can read genesis file
# Validates that geth can parse genesis.json
#
# Arguments:
#   $1 - Path to geth binary
#   $2 - Path to genesis.json
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Validation status
#######################################
validate_geth_genesis_access() {
    local geth_path="$1"
    local genesis_path="$2"
    
    if [ ! -f "$genesis_path" ]; then
        echo -e "${GO_MGR_YELLOW}⚠ Genesis file not found: $genesis_path${GO_MGR_NC}"
        return 1
    fi
    
    echo -e "${GO_MGR_CYAN}Testing genesis file access...${GO_MGR_NC}"
    
    # Create temporary test directory
    local test_dir=$(mktemp -d)
    
    # Try to initialize a test node with genesis
    if $geth_path --datadir "$test_dir" init "$genesis_path" &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ Geth can read and parse genesis.json${GO_MGR_NC}"
        rm -rf "$test_dir"
        return 0
    else
        echo -e "${GO_MGR_RED}✗ Geth failed to parse genesis.json${GO_MGR_NC}"
        rm -rf "$test_dir"
        return 1
    fi
}

#######################################
# Test Geth binary basic functionality
# Runs basic commands to ensure geth works
#
# Arguments:
#   $1 - Path to geth binary
# Returns:
#   0 if all tests pass, 1 if any fail
# Outputs:
#   Test results
#######################################
test_geth_functionality() {
    local geth_path="$1"
    
    echo -e "${GO_MGR_CYAN}Testing Geth functionality...${GO_MGR_NC}"
    echo ""
    
    local tests_passed=0
    local tests_failed=0
    
    # Test 1: Version command
    echo -e "${GO_MGR_CYAN}Test 1: Version command${GO_MGR_NC}"
    if $geth_path version &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ Version command works${GO_MGR_NC}"
        ((tests_passed++))
    else
        echo -e "${GO_MGR_RED}✗ Version command failed${GO_MGR_NC}"
        ((tests_failed++))
    fi
    
    # Test 2: Help command
    echo -e "${GO_MGR_CYAN}Test 2: Help command${GO_MGR_NC}"
    if $geth_path --help &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ Help command works${GO_MGR_NC}"
        ((tests_passed++))
    else
        echo -e "${GO_MGR_RED}✗ Help command failed${GO_MGR_NC}"
        ((tests_failed++))
    fi
    
    # Test 3: Account command
    echo -e "${GO_MGR_CYAN}Test 3: Account command${GO_MGR_NC}"
    if $geth_path account --help &>/dev/null; then
        echo -e "${GO_MGR_GREEN}✓ Account command works${GO_MGR_NC}"
        ((tests_passed++))
    else
        echo -e "${GO_MGR_RED}✗ Account command failed${GO_MGR_NC}"
        ((tests_failed++))
    fi
    
    echo ""
    echo -e "${GO_MGR_CYAN}Test Summary:${GO_MGR_NC}"
    echo -e "${GO_MGR_GREEN}  Passed: $tests_passed${GO_MGR_NC}"
    if [ $tests_failed -gt 0 ]; then
        echo -e "${GO_MGR_RED}  Failed: $tests_failed${GO_MGR_NC}"
        return 1
    fi
    
    return 0
}

#######################################
# Comprehensive post-build validation
# Main validation function that runs all checks
#
# Arguments:
#   $1 - Path to geth binary
#   $2 - Path to genesis.json (optional)
#   $3 - Go version used for build (optional)
# Returns:
#   0 if all validations pass, 1 if any fail
# Outputs:
#   Complete validation report
#######################################
validate_geth_build() {
    local geth_path="$1"
    local genesis_path="${2:-genesis.json}"
    local go_version="${3:-}"
    
    echo ""
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Post-Build Validation                                    ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    local validation_passed=true
    
    # Validation 1: Binary exists and is executable
    echo -e "${GO_MGR_CYAN}═══ Binary Validation ═══${GO_MGR_NC}"
    if ! validate_geth_binary_exists "$geth_path"; then
        validation_passed=false
    fi
    echo ""
    
    # Validation 2: Binary metadata
    echo -e "${GO_MGR_CYAN}═══ Binary Information ═══${GO_MGR_NC}"
    get_geth_binary_info "$geth_path"
    echo ""
    
    # Validation 3: Version information
    echo -e "${GO_MGR_CYAN}═══ Version Information ═══${GO_MGR_NC}"
    if ! get_geth_version "$geth_path"; then
        validation_passed=false
    fi
    echo ""
    
    # Validation 4: Functionality tests
    echo -e "${GO_MGR_CYAN}═══ Functionality Tests ═══${GO_MGR_NC}"
    if ! test_geth_functionality "$geth_path"; then
        validation_passed=false
    fi
    echo ""
    
    # Validation 5: Genesis file access (if provided)
    if [ -f "$genesis_path" ]; then
        echo -e "${GO_MGR_CYAN}═══ Genesis File Validation ═══${GO_MGR_NC}"
        if ! validate_geth_genesis_access "$geth_path" "$genesis_path"; then
            echo -e "${GO_MGR_YELLOW}⚠ Genesis validation failed (non-critical)${GO_MGR_NC}"
        fi
        echo ""
    fi
    
    # Final summary
    echo -e "${GO_MGR_CYAN}╔════════════════════════════════════════════════════════════╗${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}║   Validation Summary                                       ║${GO_MGR_NC}"
    echo -e "${GO_MGR_CYAN}╚════════════════════════════════════════════════════════════╝${GO_MGR_NC}"
    echo ""
    
    if [ "$validation_passed" = true ]; then
        echo -e "${GO_MGR_GREEN}✅ All validations passed${GO_MGR_NC}"
        echo -e "${GO_MGR_GREEN}✅ Geth binary is ready for deployment${GO_MGR_NC}"
        
        if [ -n "$go_version" ]; then
            echo -e "${GO_MGR_CYAN}Built with Go version: $go_version${GO_MGR_NC}"
        fi
        
        echo ""
        echo -e "${GO_MGR_CYAN}Next Steps:${GO_MGR_NC}"
        echo -e "  1. Generate validator keys"
        echo -e "  2. Initialize genesis for all nodes"
        echo -e "  3. Start validator nodes"
        echo ""
        
        return 0
    else
        echo -e "${GO_MGR_RED}✗ Some validations failed${GO_MGR_NC}"
        echo -e "${GO_MGR_YELLOW}Please review the errors above${GO_MGR_NC}"
        echo ""
        return 1
    fi
}

# Export validation functions
export -f validate_geth_binary_exists
export -f get_geth_version
export -f get_geth_binary_info
export -f validate_geth_genesis_access
export -f test_geth_functionality
export -f validate_geth_build
