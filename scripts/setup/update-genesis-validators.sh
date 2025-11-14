#!/bin/bash

# SilverBitcoin - Update Genesis Validators
# Updates both alloc and extraData with current validator addresses

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔧 Updating Genesis with Validators                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Collect all validator addresses
VALIDATORS=()
for i in {1..24}; do
    NODE_DIR="nodes/Node$(printf "%02d" $i)"
    if [ -f "$NODE_DIR/address.txt" ]; then
        ADDR=$(cat "$NODE_DIR/address.txt" | tr -d '0x' | tr '[:upper:]' '[:lower:]')
        VALIDATORS+=("$ADDR")
        echo "Node$(printf "%02d" $i): 0x$ADDR"
    fi
done

echo ""
echo "Found ${#VALIDATORS[@]} validators"

# Build extraData
# Format: 32 bytes vanity + N*20 bytes validators + 65 bytes seal
# Vanity: 32 zero bytes
EXTRA_DATA="0x"
EXTRA_DATA+="0000000000000000000000000000000000000000000000000000000000000000"

# Add validators
for addr in "${VALIDATORS[@]}"; do
    EXTRA_DATA+="$addr"
done

# Add seal (65 zero bytes)
EXTRA_DATA+="00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

echo ""
echo "ExtraData length: ${#EXTRA_DATA} chars"
echo "ExtraData: ${EXTRA_DATA:0:100}..."

# Create Python script to update genesis
cat > /tmp/update_genesis.py << 'PYEOF'
import json
import sys

# Read validator addresses from file
with open('/tmp/validators.txt', 'r') as f:
    validators = [line.strip() for line in f if line.strip()]

print(f"Updating genesis with {len(validators)} validators")

# Read genesis
with open('genesis.json', 'r') as f:
    genesis = json.load(f)

# Read extraData from file
with open('/tmp/extradata.txt', 'r') as f:
    extra_data = f.read().strip()

# Update extraData
genesis['extraData'] = extra_data
print(f"ExtraData updated: {extra_data[:66]}...")

# Update alloc
new_alloc = {}
for addr in validators:
    if addr:
        new_alloc[f'0x{addr}'] = {'balance': '0x1a784379d99db42000000'}
        print(f"Added to alloc: 0x{addr}")

# Add treasury (Node25)
try:
    with open('nodes/Node25/address.txt', 'r') as f:
        treasury = f.read().strip().replace('0x', '').lower()
        new_alloc[f'0x{treasury}'] = {'balance': '0x1a784379d99db42000000'}
        print(f"Added treasury: 0x{treasury}")
except:
    pass

genesis['alloc'] = new_alloc

# Update coinbase to first validator
if validators:
    genesis['coinbase'] = f'0x{validators[0]}'
    print(f"Coinbase set to: 0x{validators[0]}")

# Write back
with open('genesis.json', 'w') as f:
    json.dump(genesis, f, indent=2)

print("✅ Genesis updated successfully")
PYEOF

# Save validators to file
printf "%s\n" "${VALIDATORS[@]}" > /tmp/validators.txt

# Save extraData to file
echo "$EXTRA_DATA" > /tmp/extradata.txt

# Run Python script
python3 /tmp/update_genesis.py

echo -e "${GREEN}✅ Genesis.json updated with validators${NC}"
echo ""
echo "Next: Reinitialize all nodes with new genesis"
