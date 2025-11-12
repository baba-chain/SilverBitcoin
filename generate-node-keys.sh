#!/bin/bash

# SilverBitcoin - Generate Node Private Keys
# This script generates new private keys for validator nodes
# Run this ONLY on the server, NEVER commit the keys to GitHub!

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔐 SilverBitcoin - Generate Node Keys                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if geth exists
if [ ! -f "geth" ]; then
    echo -e "${RED}❌ Geth binary not found!${NC}"
    echo -e "${YELLOW}Please build geth first:${NC}"
    echo -e "  cd SilverBitcoin/node_src"
    echo -e "  go build -o geth ./cmd/geth"
    exit 1
fi

echo -e "${YELLOW}⚠️  This will generate NEW private keys for all nodes.${NC}"
echo -e "${YELLOW}⚠️  Existing keys will be backed up.${NC}"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
    echo -e "${RED}❌ Cancelled.${NC}"
    exit 0
fi

echo ""

# Backup existing keys
if [ -d "nodes" ]; then
    BACKUP_DIR="nodes-backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${YELLOW}Backing up existing keys to $BACKUP_DIR...${NC}"
    cp -r nodes "$BACKUP_DIR"
    echo -e "${GREEN}✅ Backup created${NC}"
    echo ""
fi

# Generate keys for each node
for i in {1..25}; do
    NODE_NUM=$(printf "%02d" $i)
    NODE_DIR="nodes/Node$NODE_NUM"
    
    echo -e "${CYAN}Generating key for Node$NODE_NUM...${NC}"
    
    # Create node directory
    mkdir -p "$NODE_DIR"
    
    # Create empty password file
    touch "$NODE_DIR/password.txt"
    
    # Generate new account
    ADDRESS=$(./geth account new --datadir "$NODE_DIR" --password "$NODE_DIR/password.txt" 2>&1 | grep -oP '(?<=Public address of the key:   )[0-9a-fA-Fx]+')
    
    if [ -z "$ADDRESS" ]; then
        echo -e "${RED}❌ Failed to generate key for Node$NODE_NUM${NC}"
        continue
    fi
    
    # Save address
    echo "$ADDRESS" > "$NODE_DIR/address.txt"
    
    # Extract private key from keystore
    KEYSTORE_FILE=$(ls -t "$NODE_DIR/keystore" | head -1)
    if [ -n "$KEYSTORE_FILE" ]; then
        # Note: Private key extraction requires the keystore file
        # For now, we'll just note that the keystore exists
        echo "Keystore: $KEYSTORE_FILE" > "$NODE_DIR/info.txt"
        echo "Balance: 2,000,000 SBTC (to be allocated in genesis)" >> "$NODE_DIR/info.txt"
    fi
    
    echo -e "${GREEN}✅ Node$NODE_NUM: $ADDRESS${NC}"
done

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Key Generation Complete!                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Update genesis.json with new addresses
echo -e "${YELLOW}Updating genesis.json with new addresses...${NC}"

if [ ! -f "genesis.json" ]; then
    echo -e "${RED}❌ genesis.json not found!${NC}"
    echo -e "${YELLOW}Please create genesis.json first${NC}"
else
    # Backup genesis.json
    cp genesis.json "genesis.json.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✅ genesis.json backed up${NC}"
    
    # Create new alloc section
    echo -e "${CYAN}Creating new alloc section...${NC}"
    
    # Start building the alloc JSON
    # Balance: 2,000,000 SBTC = 0x1a784379d99db42000000 (hex)
    BALANCE_HEX="0x1a784379d99db42000000"
    ALLOC_JSON="{"
    
    for i in {1..25}; do
        NODE_NUM=$(printf "%02d" $i)
        NODE_DIR="nodes/Node$NODE_NUM"
        
        if [ -f "$NODE_DIR/address.txt" ]; then
            ADDRESS=$(cat "$NODE_DIR/address.txt")
            # Remove 0x prefix if exists
            ADDRESS=${ADDRESS#0x}
            # Convert to lowercase for consistency
            ADDRESS=$(echo "$ADDRESS" | tr '[:upper:]' '[:lower:]')
            
            # Add to alloc with hex balance (same format as your genesis.json)
            if [ $i -gt 1 ]; then
                ALLOC_JSON+=","
            fi
            ALLOC_JSON+="\"0x$ADDRESS\":{\"balance\":\"$BALANCE_HEX\"}"
            
            echo -e "  ${GREEN}✅ Node$NODE_NUM: 0x$ADDRESS${NC}"
        fi
    done
    
    ALLOC_JSON+="}"
    
    # Update genesis.json using Python
    python3 << EOF
import json
import sys

try:
    # Read genesis.json
    with open('genesis.json', 'r') as f:
        genesis = json.load(f)
    
    # Parse new alloc
    new_alloc = json.loads('$ALLOC_JSON')
    
    # Update alloc section
    genesis['alloc'] = new_alloc
    
    # Write back
    with open('genesis.json', 'w') as f:
        json.dump(genesis, f, indent=2)
    
    print("✅ genesis.json updated successfully")
    sys.exit(0)
except Exception as e:
    print(f"❌ Error updating genesis.json: {e}")
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ genesis.json updated with all validator addresses${NC}"
    else
        echo -e "${RED}❌ Failed to update genesis.json${NC}"
        echo -e "${YELLOW}You may need to update it manually${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo -e "  1. ${RED}NEVER commit nodes/*/keystore/ to GitHub!${NC}"
echo -e "  2. ${RED}NEVER commit nodes/*/private_key.txt to GitHub!${NC}"
echo -e "  3. Keep these files secure and backed up"
echo -e "  4. The .gitignore file already protects these files"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Initialize genesis for all nodes"
echo -e "  2. Start nodes: ./start-all-nodes.sh"
