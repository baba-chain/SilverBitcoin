const hre = require("hardhat");

async function main() {
  // Contract address - deploy ettikten sonra buraya yaz
  const CONTRACT_ADDRESS = process.env.USDT_ADDRESS || "BURAYA_CONTRACT_ADRESINI_YAZ";

  if (CONTRACT_ADDRESS === "BURAYA_CONTRACT_ADRESINI_YAZ") {
    console.log("❌ Error: Please set USDT_ADDRESS environment variable");
    console.log("   Example: USDT_ADDRESS=0x... node scripts/test-usdt.js");
    process.exit(1);
  }

  console.log("🧪 Testing SilverUSDT Contract\n");
  console.log("📍 Contract Address:", CONTRACT_ADDRESS);

  const [owner, user1, user2] = await hre.ethers.getSigners();
  console.log("👤 Owner:", owner.address);
  console.log("👤 User1:", user1.address);
  console.log("👤 User2:", user2.address, "\n");

  // Get contract instance
  const SilverUSDT = await hre.ethers.getContractFactory("SilverUSDT");
  const usdt = SilverUSDT.attach(CONTRACT_ADDRESS);

  // Test 1: Check basic info
  console.log("📊 Test 1: Basic Information");
  const name = await usdt.name();
  const symbol = await usdt.symbol();
  const decimals = await usdt.decimals();
  const totalSupply = await usdt.totalSupply();
  console.log("   Name:", name);
  console.log("   Symbol:", symbol);
  console.log("   Decimals:", decimals);
  console.log("   Total Supply:", hre.ethers.utils.formatUnits(totalSupply, decimals), "\n");

  // Test 2: Transfer tokens
  console.log("💸 Test 2: Transfer Tokens");
  const transferAmount = hre.ethers.utils.parseUnits("1000", 6); // 1000 USDT
  console.log("   Transferring 1000 sUSDT to User1...");
  const tx1 = await usdt.transfer(user1.address, transferAmount);
  await tx1.wait();
  const user1Balance = await usdt.balanceOf(user1.address);
  console.log("   ✅ User1 Balance:", hre.ethers.utils.formatUnits(user1Balance, 6), "sUSDT\n");

  // Test 3: Mint tokens
  console.log("🏭 Test 3: Mint New Tokens");
  const mintAmount = hre.ethers.utils.parseUnits("10000", 6); // 10000 USDT
  console.log("   Minting 10000 sUSDT to User2...");
  const tx2 = await usdt.mint(user2.address, 10000);
  await tx2.wait();
  const user2Balance = await usdt.balanceOf(user2.address);
  console.log("   ✅ User2 Balance:", hre.ethers.utils.formatUnits(user2Balance, 6), "sUSDT\n");

  // Test 4: Blacklist
  console.log("🚫 Test 4: Blacklist Feature");
  console.log("   Blacklisting User1...");
  const tx3 = await usdt.blacklist(user1.address);
  await tx3.wait();
  const isBlacklisted = await usdt.isBlacklisted(user1.address);
  console.log("   ✅ User1 Blacklisted:", isBlacklisted);
  
  console.log("   Trying to transfer from blacklisted address...");
  try {
    const usdtAsUser1 = usdt.connect(user1);
    await usdtAsUser1.transfer(user2.address, 100);
    console.log("   ❌ Transfer should have failed!");
  } catch (error) {
    console.log("   ✅ Transfer blocked (as expected)\n");
  }

  // Test 5: Unblacklist
  console.log("✅ Test 5: Unblacklist");
  console.log("   Removing User1 from blacklist...");
  const tx4 = await usdt.unBlacklist(user1.address);
  await tx4.wait();
  const isStillBlacklisted = await usdt.isBlacklisted(user1.address);
  console.log("   ✅ User1 Blacklisted:", isStillBlacklisted, "\n");

  // Test 6: Pause
  console.log("⏸️  Test 6: Pause Feature");
  console.log("   Pausing contract...");
  const tx5 = await usdt.pause();
  await tx5.wait();
  console.log("   ✅ Contract paused");
  
  console.log("   Trying to transfer while paused...");
  try {
    await usdt.transfer(user1.address, 100);
    console.log("   ❌ Transfer should have failed!");
  } catch (error) {
    console.log("   ✅ Transfer blocked (as expected)");
  }
  
  console.log("   Unpausing contract...");
  const tx6 = await usdt.unpause();
  await tx6.wait();
  console.log("   ✅ Contract unpaused\n");

  console.log("🎉 All tests completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Test failed:", error);
    process.exit(1);
  });
