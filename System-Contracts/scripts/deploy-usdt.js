const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying SilverUSDT to SilverBitcoin...\n");

  // Initial supply: 1 billion USDT
  const initialSupply = 1_000_000_000;

  console.log("📝 Deployment Parameters:");
  console.log("   Token Name: Silver USDT");
  console.log("   Token Symbol: sUSDT");
  console.log("   Decimals: 6");
  console.log(`   Initial Supply: ${initialSupply.toLocaleString()} sUSDT\n`);

  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("👤 Deploying with account:", deployer.address);
  
  const balance = await deployer.getBalance();
  console.log("💰 Account balance:", hre.ethers.utils.formatEther(balance), "SBC\n");

  // Deploy contract
  console.log("⏳ Deploying contract...");
  const SilverUSDT = await hre.ethers.getContractFactory("SilverUSDT");
  const usdt = await SilverUSDT.deploy(initialSupply);

  await usdt.deployed();

  console.log("\n✅ SilverUSDT deployed successfully!");
  console.log("📍 Contract Address:", usdt.address);
  console.log("👤 Owner Address:", deployer.address);
  
  // Verify deployment
  const name = await usdt.name();
  const symbol = await usdt.symbol();
  const decimals = await usdt.decimals();
  const totalSupply = await usdt.totalSupply();
  const ownerBalance = await usdt.balanceOf(deployer.address);

  console.log("\n📊 Contract Details:");
  console.log("   Name:", name);
  console.log("   Symbol:", symbol);
  console.log("   Decimals:", decimals);
  console.log("   Total Supply:", hre.ethers.utils.formatUnits(totalSupply, decimals), symbol);
  console.log("   Owner Balance:", hre.ethers.utils.formatUnits(ownerBalance, decimals), symbol);

  console.log("\n🎉 Deployment Complete!");
  console.log("\n📝 Save this information:");
  console.log("   Contract Address:", usdt.address);
  console.log("   Network: SilverBitcoin (Chain ID: 5200)");
  console.log("   Block Explorer: Add this contract to your explorer");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
