#!/bin/bash

# SilverBitcoin - Automatic Validator Voting
# This script automatically votes for new validators who have staked at least 1000 SBTC

NODE_NUM=$1

if [ -z "$NODE_NUM" ]; then
    echo "Usage: $0 <node_number>"
    exit 1
fi

# Get the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

NODE_DIR="nodes/Node$(printf "%02d" $NODE_NUM)"
IPC_PATH="$NODE_DIR/geth.ipc"

# Minimum stake requirement: 1000 SBTC = 1000 * 10^18 wei
MIN_STAKE="1000000000000000000000"  # 1000 SBTC in wei

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🗳️  Auto-Voting for Node$(printf "%02d" $NODE_NUM)                           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}Minimum stake requirement: 1000 SBTC${NC}"
echo ""

while true; do
    # Get current validators
    CURRENT_VALIDATORS=$(./geth attach "$IPC_PATH" --exec "clique.getSigners()" 2>/dev/null)
    
    if [ -z "$CURRENT_VALIDATORS" ]; then
        echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Cannot connect to node, retrying...${NC}"
        sleep 30
        continue
    fi
    
    # Get all accounts from the blockchain
    # We'll check accounts that have balance >= 1000 SBTC
    
    # Get pending proposals
    PROPOSALS=$(./geth attach "$IPC_PATH" --exec "clique.proposals()" 2>/dev/null)
    
    # Check for new addresses with sufficient balance
    # Get all accounts (this is a simplified version - in production you'd scan blocks)
    ALL_ACCOUNTS=$(./geth attach "$IPC_PATH" --exec "eth.accounts" 2>/dev/null)
    
    # For each account, check if:
    # 1. Balance >= 1000 SBTC
    # 2. Not already a validator
    # 3. Not already proposed
    
    if [ ! -z "$ALL_ACCOUNTS" ]; then
        # Parse accounts array
        ACCOUNTS=$(echo "$ALL_ACCOUNTS" | grep -oE '0x[a-fA-F0-9]{40}')
        
        for ADDR in $ACCOUNTS; do
            # Check if already a validator
            if echo "$CURRENT_VALIDATORS" | grep -qi "$ADDR"; then
                continue
            fi
            
            # Check balance
            BALANCE=$(./geth attach "$IPC_PATH" --exec "eth.getBalance('$ADDR')" 2>/dev/null)
            
            if [ ! -z "$BALANCE" ]; then
                # Compare balance with minimum stake
                # Convert to comparable format
                BALANCE_DEC=$(echo "$BALANCE" | tr -d '"')
                
                # Simple comparison (both are in wei)
                if [ "$BALANCE_DEC" -ge "$MIN_STAKE" ] 2>/dev/null; then
                    # Check if already proposed
                    if ! echo "$PROPOSALS" | grep -qi "$ADDR"; then
                        echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] Found eligible validator: $ADDR${NC}"
                        echo -e "${CYAN}  Balance: $(./geth attach "$IPC_PATH" --exec "web3.fromWei(eth.getBalance('$ADDR'), 'ether')" 2>/dev/null) SBTC${NC}"
                        echo -e "${YELLOW}  Proposing as validator...${NC}"
                        
                        # Propose the validator
                        RESULT=$(./geth attach "$IPC_PATH" --exec "clique.propose('$ADDR', true)" 2>/dev/null)
                        
                        if [ $? -eq 0 ]; then
                            echo -e "${GREEN}  ✓ Vote submitted successfully${NC}"
                        else
                            echo -e "${YELLOW}  ⚠ Vote submission failed${NC}"
                        fi
                    fi
                fi
            fi
        done
    fi
    
    # Also vote for any existing proposals
    if [ ! -z "$PROPOSALS" ] && [ "$PROPOSALS" != "{}" ]; then
        PROP_ADDRESSES=$(echo "$PROPOSALS" | grep -oE '0x[a-fA-F0-9]{40}')
        
        for ADDR in $PROP_ADDRESSES; do
            # Check if this address has sufficient balance
            BALANCE=$(./geth attach "$IPC_PATH" --exec "eth.getBalance('$ADDR')" 2>/dev/null)
            BALANCE_DEC=$(echo "$BALANCE" | tr -d '"')
            
            if [ "$BALANCE_DEC" -ge "$MIN_STAKE" ] 2>/dev/null; then
                echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Voting YES for pending proposal: $ADDR${NC}"
                ./geth attach "$IPC_PATH" --exec "clique.propose('$ADDR', true)" 2>/dev/null
            else
                echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Voting NO for proposal (insufficient stake): $ADDR${NC}"
                ./geth attach "$IPC_PATH" --exec "clique.propose('$ADDR', false)" 2>/dev/null
            fi
        done
    fi
    
    # Check every 60 seconds
    sleep 60
done
