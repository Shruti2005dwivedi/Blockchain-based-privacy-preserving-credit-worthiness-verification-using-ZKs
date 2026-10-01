const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

const PTAU_URL = "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_12.ptau";
const PTAU_FILE = "powersOfTau28_hez_final_12.ptau";

async function run(command, description) {
  console.log(`\n📦 ${description}...`);
  try {
    const { stdout, stderr } = await execPromise(command);
    if (stdout) console.log(stdout);
    if (stderr) console.error(stderr);
    console.log(`✅ ${description} complete`);
    return true;
  } catch (error) {
    console.error(`❌ ${description} failed:`, error.message);
    return false;
  }
}

async function downloadPtau() {
  const keysDir = path.join(__dirname, '..', 'keys');
  const ptauPath = path.join(keysDir, PTAU_FILE);
  
  if (fs.existsSync(ptauPath)) {
    console.log(`✅ Powers of Tau file already exists: ${PTAU_FILE}`);
    return true;
  }
  
  console.log(`\n📦 Downloading Powers of Tau file...`);
  console.log(`   This may take a few minutes (~200MB file)`);
  
  try {
    if (process.platform === 'win32') {
      // Windows using PowerShell
      await execPromise(`powershell -Command "Invoke-WebRequest -Uri '${PTAU_URL}' -OutFile '${ptauPath}'"`);
    } else {
      // Unix-like systems
      await execPromise(`curl -o "${ptauPath}" "${PTAU_URL}"`);
    }
    console.log(`✅ Downloaded ${PTAU_FILE}`);
    return true;
  } catch (error) {
    console.error(`❌ Download failed:`, error.message);
    console.log(`\n⚠️  Please download manually from:`);
    console.log(`   ${PTAU_URL}`);
    console.log(`   Save to: ${ptauPath}`);
    return false;
  }
}

async function main() {
  console.log('🚀 Zero-Knowledge Proof Setup for Creditworthiness Verification');
  console.log('================================================================\n');
  
  const rootDir = path.join(__dirname, '..');
  const buildDir = path.join(rootDir, 'build');
  const keysDir = path.join(rootDir, 'keys');
  const contractsDir = path.join(rootDir, 'contracts');
  const circuitPath = path.join(rootDir, 'circuits', 'creditworthiness.circom');
  
  // Ensure directories exist
  [buildDir, keysDir, contractsDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });
  
  // Check if circom is installed
  try {
    await execPromise('circom --version');
  } catch (error) {
    console.error('❌ Circom compiler not found!');
    console.log('\n📖 Installation instructions:');
    console.log('   Visit: https://docs.circom.io/getting-started/installation/');
    process.exit(1);
  }
  
  // Step 1: Compile circuit
  const compileSuccess = await run(
    `circom "${circuitPath}" --r1cs --wasm --sym --c -o "${buildDir}"`,
    'Compiling Circom circuit'
  );
  if (!compileSuccess) process.exit(1);
  
  // Check constraint count
  console.log('\n📊 Circuit Statistics:');
  const r1csPath = path.join(buildDir, 'creditworthiness.r1cs');
  if (fs.existsSync(r1csPath)) {
    await run(
      `snarkjs r1cs info "${r1csPath}"`,
      'Reading circuit info'
    );
  }
  
  // Step 2: Download Powers of Tau
  const ptauSuccess = await downloadPtau();
  if (!ptauSuccess) process.exit(1);
  
  const ptauPath = path.join(keysDir, PTAU_FILE);
  
  // Step 3: Generate zkey (Groth16 setup)
  const zkeyPath0 = path.join(keysDir, 'creditworthiness_0000.zkey');
  const setupSuccess = await run(
    `snarkjs groth16 setup "${r1csPath}" "${ptauPath}" "${zkeyPath0}"`,
    'Groth16 setup (phase 1)'
  );
  if (!setupSuccess) process.exit(1);
  
  // Step 4: Contribute to phase 2
  const zkeyPath1 = path.join(keysDir, 'creditworthiness_0001.zkey');
  const contributeSuccess = await run(
    `snarkjs zkey contribute "${zkeyPath0}" "${zkeyPath1}" --name="First contribution" -v -e="random entropy"`,
    'Phase 2 contribution'
  );
  if (!contributeSuccess) process.exit(1);
  
  // Rename to final zkey
  const zkeyFinal = path.join(keysDir, 'creditworthiness_final.zkey');
  fs.renameSync(zkeyPath1, zkeyFinal);
  console.log(`✅ Renamed to creditworthiness_final.zkey`);
  
  // Clean up intermediate zkey
  if (fs.existsSync(zkeyPath0)) {
    fs.unlinkSync(zkeyPath0);
  }
  
  // Step 5: Export verification key
  const vkeyPath = path.join(keysDir, 'verification_key.json');
  const vkeySuccess = await run(
    `snarkjs zkey export verificationkey "${zkeyFinal}" "${vkeyPath}"`,
    'Exporting verification key'
  );
  if (!vkeySuccess) process.exit(1);
  
  // Step 6: Generate Solidity verifier
  const verifierPath = path.join(contractsDir, 'Groth16Verifier.sol');
  const verifierSuccess = await run(
    `snarkjs zkey export solidityverifier "${zkeyFinal}" "${verifierPath}"`,
    'Generating Solidity verifier'
  );
  if (!verifierSuccess) process.exit(1);
  
  // Copy to blockchain contracts directory
  const blockchainContractsDir = path.join(rootDir, '..', 'blockchain', 'contracts');
  if (fs.existsSync(blockchainContractsDir)) {
    const destPath = path.join(blockchainContractsDir, 'Groth16Verifier.sol');
    fs.copyFileSync(verifierPath, destPath);
    console.log(`✅ Copied verifier to blockchain/contracts/`);
  }
  
  console.log('\n🎉 Zero-Knowledge Proof Setup Complete!');
  console.log('================================================\n');
  console.log('📁 Generated files:');
  console.log(`   Build: ${buildDir}`);
  console.log(`   Keys: ${keysDir}`);
  console.log(`   Verifier: ${verifierPath}`);
  console.log('\n✨ You can now deploy the smart contracts!');
}

main().catch(error => {
  console.error('❌ Setup failed:', error);
  process.exit(1);
});
