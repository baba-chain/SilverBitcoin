// Hardhat Deploy Script for SilverBitcoin Staking Contract
// Run: npx hardhat run hardhat-deploy-script.js --network localhost

const hre = require("hardhat");

async function main() {
    console.log("🚀 Deploying SilverBitcoin Staking Contract...\n");

    // Get deployer account
    const [deployer] = await hre.ethers.getSigners();
    console.log("📝 Deploying with account:", deployer.address);
    console.log("💰 Account balance:", (await deployer.getBalance()).toString(), "wei\n");

    // Deploy contract
    const SilverBitcoinStaking = await hre.ethers.getContractFactory("SilverBitcoinStaking");
    const staking = await SilverBitcoinStaking.deploy();

    await staking.deployed();

    console.log("✅ Contract deployed successfully!");
    console.log("📍 Contract address:", staking.address);
    console.log("\n🔧 Update your config.js with:");
    console.log(`CONTRACT_ADDRESS: '${staking.address}',`);
    console.log("\n📡 RPC URL: http://127.0.0.1:8545");
    console.log("🆔 Chain ID: 31337");
    console.log("\n🎉 Your local testnet is ready!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
