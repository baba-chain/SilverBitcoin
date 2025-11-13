const { ethers } = require("hardhat");

async function main() {
  console.log("🔐 Creating new wallet for deployment...\n");

  // Create random wallet
  const wallet = ethers.Wallet.createRandom();

  console.log("✅ Wallet created successfully!\n");
  console.log("📋 Wallet Information:");
  console.log("   Address:", wallet.address);
  console.log("   Private Key:", wallet.privateKey);
  console.log("   Mnemonic:", wallet.mnemonic.phrase);

  console.log("\n⚠️  IMPORTANT:");
  console.log("   1. Save this private key securely!");
  console.log("   2. Add to System-Contracts/.env:");
  console.log(`      PRIVATE_KEY=${wallet.privateKey.slice(2)}`);
  console.log("   3. Send some SBC to this address for gas:");
  console.log(`      ${wallet.address}`);
  console.log("\n💡 You can send SBC from your node's account using geth console");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
