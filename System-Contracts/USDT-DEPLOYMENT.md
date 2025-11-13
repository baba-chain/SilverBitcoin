# SilverUSDT Deployment Guide

## 📋 Overview

SilverUSDT is a USDT-like stablecoin for the SilverBitcoin blockchain with the following features:

- ✅ **ERC20 Standard**: Fully compatible with ERC20
- ✅ **6 Decimals**: Same as USDT (not 18)
- ✅ **Pausable**: Emergency pause for all transfers
- ✅ **Blacklist**: Block malicious addresses
- ✅ **Mintable**: Owner can mint new tokens
- ✅ **Burnable**: Tokens can be burned
- ✅ **Ownable**: Owner-controlled admin functions

## 🚀 Deployment Steps

### 1. Install Dependencies

```bash
cd System-Contracts
npm install
```

### 2. Compile Contract

```bash
npx hardhat compile
```

### 3. Deploy to SilverBitcoin

**Option A: Deploy to Remote Node (34.122.141.167)**

```bash
# Make sure your node is running on the server
npx hardhat run scripts/deploy-usdt.js --network silverbitcoin
```

**Option B: Deploy to Local Node**

```bash
# Make sure your local node is running
npx hardhat run scripts/deploy-usdt.js --network local
```

### 4. Save Contract Address

After deployment, you'll see:
```
✅ SilverUSDT deployed successfully!
📍 Contract Address: 0x...
```

**Save this address!** You'll need it for all interactions.

## 🧪 Testing

Test the deployed contract:

```bash
# Set the contract address
export USDT_ADDRESS=0xYOUR_CONTRACT_ADDRESS

# Run tests
npx hardhat run scripts/test-usdt.js --network silverbitcoin
```

## 📝 Contract Functions

### User Functions

```javascript
// Transfer tokens
await usdt.transfer(recipientAddress, amount);

// Approve spending
await usdt.approve(spenderAddress, amount);

// Transfer from approved address
await usdt.transferFrom(fromAddress, toAddress, amount);

// Burn tokens
await usdt.burn(amount);

// Check balance
const balance = await usdt.balanceOf(address);
```

### Owner Functions

```javascript
// Mint new tokens (amount in tokens, not wei)
await usdt.mint(toAddress, 1000000); // Mint 1M USDT

// Pause all transfers
await usdt.pause();

// Unpause
await usdt.unpause();

// Blacklist address
await usdt.blacklist(address);

// Remove from blacklist
await usdt.unBlacklist(address);

// Check if blacklisted
const isBlacklisted = await usdt.isBlacklisted(address);
```

## 💡 Usage Examples

### Example 1: Send USDT to User

```javascript
const { ethers } = require("hardhat");

async function sendUSDT() {
  const usdt = await ethers.getContractAt("SilverUSDT", "0xCONTRACT_ADDRESS");
  
  // Send 1000 USDT (remember: 6 decimals)
  const amount = ethers.utils.parseUnits("1000", 6);
  const tx = await usdt.transfer("0xRECIPIENT_ADDRESS", amount);
  await tx.wait();
  
  console.log("Sent 1000 USDT");
}
```

### Example 2: Mint New Tokens

```javascript
async function mintTokens() {
  const usdt = await ethers.getContractAt("SilverUSDT", "0xCONTRACT_ADDRESS");
  
  // Mint 1 million USDT (function takes token amount, not wei)
  const tx = await usdt.mint("0xRECIPIENT_ADDRESS", 1000000);
  await tx.wait();
  
  console.log("Minted 1,000,000 USDT");
}
```

### Example 3: Emergency Pause

```javascript
async function emergencyPause() {
  const usdt = await ethers.getContractAt("SilverUSDT", "0xCONTRACT_ADDRESS");
  
  // Pause all transfers
  const tx = await usdt.pause();
  await tx.wait();
  
  console.log("Contract paused - all transfers blocked");
}
```

## 🔐 Security Notes

1. **Owner Private Key**: Keep the deployer's private key secure - it controls minting and admin functions
2. **Blacklist**: Use carefully - blacklisted addresses cannot send or receive tokens
3. **Pause**: Only use in emergencies - affects all users
4. **Minting**: Monitor total supply to maintain stablecoin peg

## 📊 Token Information

- **Name**: Silver USDT
- **Symbol**: sUSDT
- **Decimals**: 6
- **Initial Supply**: 1,000,000,000 sUSDT (configurable)
- **Network**: SilverBitcoin (Chain ID: 5200)

## 🌐 Adding to Wallets

Users can add sUSDT to MetaMask:

1. Open MetaMask
2. Click "Import tokens"
3. Enter:
   - Token Contract Address: `0xYOUR_CONTRACT_ADDRESS`
   - Token Symbol: `sUSDT`
   - Token Decimals: `6`

## 🔧 Troubleshooting

### "Insufficient funds" error
- Make sure deployer has enough SBC for gas

### "Network not found" error
- Check if node is running: `./node-status.sh`
- Verify RPC endpoint in hardhat.config.js

### "Transaction timeout" error
- Increase timeout in hardhat.config.js
- Check if blockchain is producing blocks

## 📞 Support

For issues or questions, check the SilverBitcoin documentation or GitHub issues.
