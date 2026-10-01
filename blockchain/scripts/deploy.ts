import { ethers, network } from "hardhat";
import fs from "fs";
import path from "path";

/**
 * Deployment script for creditworthiness verification contracts
 * 
 * Deploys in order:
 * 1. Groth16Verifier (ZK proof verifier)
 * 2. CredentialSBT (Soulbound token)
 * 3. CreditworthinessRegistry (main registry)
 * 
 * Then configures the SBT contract with the registry address
 */

async function main() {
  console.log("🚀 Starting deployment...");
  console.log(`📡 Network: ${network.name}`);
  console.log("=" .repeat(60));
  
  const [deployer] = await ethers.getSigners();
  console.log(`\n👤 Deploying with account: ${deployer.address}`);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log(`💰 Account balance: ${ethers.formatEther(balance)} ETH\n`);
  
  // ============================================
  // STEP 1: Deploy Groth16Verifier
  // ============================================
  
  console.log("📦 Step 1: Deploying Groth16Verifier...");
  
  // Check if verifier contract exists
  const verifierPath = path.join(__dirname, "../contracts/Groth16Verifier.sol");
  if (!fs.existsSync(verifierPath)) {
    console.error("❌ Groth16Verifier.sol not found!");
    console.log("   Please run: cd zk-setup && npm run setup");
    console.log("   This will generate the verifier contract from the circuit");
    process.exit(1);
  }
  
  const VerifierFactory = await ethers.getContractFactory("Groth16Verifier");
  const verifier = await VerifierFactory.deploy();
  await verifier.waitForDeployment();
  const verifierAddress = await verifier.getAddress();
  
  console.log(`✅ Groth16Verifier deployed to: ${verifierAddress}\n`);
  
  // ============================================
  // STEP 2: Deploy CredentialSBT
  // ============================================
  
  console.log("📦 Step 2: Deploying CredentialSBT (Soulbound Token)...");
  
  const SBTFactory = await ethers.getContractFactory("CredentialSBT");
  const sbt = await SBTFactory.deploy();
  await sbt.waitForDeployment();
  const sbtAddress = await sbt.getAddress();
  
  console.log(`✅ CredentialSBT deployed to: ${sbtAddress}\n`);
  
  // ============================================
  // STEP 3: Deploy CreditworthinessRegistry
  // ============================================
  
  console.log("📦 Step 3: Deploying CreditworthinessRegistry...");
  
  const RegistryFactory = await ethers.getContractFactory("CreditworthinessRegistry");
  const registry = await RegistryFactory.deploy(verifierAddress, sbtAddress);
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  
  console.log(`✅ CreditworthinessRegistry deployed to: ${registryAddress}\n`);
  
  // ============================================
  // STEP 4: Configure SBT with Registry
  // ============================================
  
  console.log("⚙️  Step 4: Configuring contracts...");
  
  const setRegistryTx = await sbt.setRegistry(registryAddress);
  await setRegistryTx.wait();
  
  console.log(`✅ Registry address set in SBT contract\n`);
  
  // ============================================
  // STEP 5: Verify deployment
  // ============================================
  
  console.log("🔍 Step 5: Verifying deployment...");
  
  const sbtRegistry = await sbt.registryContract();
  const registryVerifier = await registry.verifierContract();
  const registrySBT = await registry.sbtContract();
  
  console.log(`   SBT registry address: ${sbtRegistry}`);
  console.log(`   Registry verifier: ${registryVerifier}`);
  console.log(`   Registry SBT: ${registrySBT}`);
  
  if (sbtRegistry !== registryAddress) {
    console.error("❌ SBT registry mismatch!");
    process.exit(1);
  }
  if (registryVerifier !== verifierAddress) {
    console.error("❌ Registry verifier mismatch!");
    process.exit(1);
  }
  if (registrySBT !== sbtAddress) {
    console.error("❌ Registry SBT mismatch!");
    process.exit(1);
  }
  
  console.log("✅ All addresses verified correctly\n");
  
  // ============================================
  // STEP 6: Save deployment info
  // ============================================
  
  const deployment = {
    network: network.name,
    chainId: network.config.chainId,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      Groth16Verifier: verifierAddress,
      CredentialSBT: sbtAddress,
      CreditworthinessRegistry: registryAddress
    }
  };
  
  const deploymentsDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }
  
  const filename = `${network.name}-${Date.now()}.json`;
  const filepath = path.join(deploymentsDir, filename);
  fs.writeFileSync(filepath, JSON.stringify(deployment, null, 2));
  
  console.log(`💾 Deployment info saved to: deployments/${filename}\n`);
  
  // ============================================
  // SUMMARY
  // ============================================
  
  console.log("=" .repeat(60));
  console.log("🎉 DEPLOYMENT COMPLETE!");
  console.log("=" .repeat(60));
  console.log("\n📋 Contract Addresses:");
  console.log(`   Groth16Verifier:         ${verifierAddress}`);
  console.log(`   CredentialSBT:           ${sbtAddress}`);
  console.log(`   CreditworthinessRegistry: ${registryAddress}`);
  
  if (network.name === "sepolia") {
    console.log("\n🔗 Etherscan Verification:");
    console.log(`   npx hardhat verify --network sepolia ${verifierAddress}`);
    console.log(`   npx hardhat verify --network sepolia ${sbtAddress}`);
    console.log(`   npx hardhat verify --network sepolia ${registryAddress} ${verifierAddress} ${sbtAddress}`);
  }
  
  console.log("\n✨ Next steps:");
  console.log("   1. Update .env files with contract addresses");
  console.log("   2. Test proof generation with test script");
  console.log("   3. Submit a test credential to the registry");
  console.log("\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
