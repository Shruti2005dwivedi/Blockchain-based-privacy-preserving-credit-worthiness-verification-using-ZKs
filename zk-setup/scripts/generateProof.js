const snarkjs = require("snarkjs");
const fs = require("fs");
const path = require("path");

/**
 * Generate a zero-knowledge proof for creditworthiness verification
 * 
 * This script demonstrates the complete proof generation process:
 * 1. Load private financial data (stays local, never transmitted)
 * 2. Load policy thresholds (public data)
 * 3. Generate witness from circuit
 * 4. Generate Groth16 proof
 * 5. Export proof in Solidity-compatible format
 */

async function generateProof(input, outputFile = null) {
  console.log("🔐 Generating Zero-Knowledge Proof");
  console.log("=" .repeat(60));
  
  const rootDir = path.join(__dirname, "..");
  const wasmFile = path.join(rootDir, "build/creditworthiness_js/creditworthiness.wasm");
  const zkeyFile = path.join(rootDir, "keys/creditworthiness_final.zkey");
  
  // Check if files exist
  if (!fs.existsSync(wasmFile)) {
    console.error("❌ WASM file not found!");
    console.log("   Please run: npm run setup");
    process.exit(1);
  }
  
  if (!fs.existsSync(zkeyFile)) {
    console.error("❌ Proving key not found!");
    console.log("   Please run: npm run setup");
    process.exit(1);
  }
  
  console.log("\n📊 Input Data:");
  console.log("   Private Inputs (hidden):");
  console.log(`      Income:        ${input.income}`);
  console.log(`      Credit Score:  ${input.creditScore}`);
  console.log(`      Payment Ratio: ${input.paymentRatio}%`);
  console.log("   Public Inputs (visible on-chain):");
  console.log(`      Min Income:        ${input.minIncome}`);
  console.log(`      Min Credit Score:  ${input.minCreditScore}`);
  console.log(`      Min Payment Ratio: ${input.minPaymentRatio}%`);
  
  try {
    // Step 1: Generate witness
    console.log("\n⚙️  Step 1: Calculating witness...");
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
      input,
      wasmFile,
      zkeyFile
    );
    console.log("✅ Witness calculated");
    
    // Step 2: Verify proof locally
    console.log("\n🔍 Step 2: Verifying proof locally...");
    const vkeyFile = path.join(rootDir, "keys/verification_key.json");
    const vKey = JSON.parse(fs.readFileSync(vkeyFile));
    const verified = await snarkjs.groth16.verify(vKey, publicSignals, proof);
    
    if (verified) {
      console.log("✅ Proof verified successfully!");
    } else {
      console.log("❌ Proof verification failed!");
      console.log("   This means the private data does NOT satisfy the thresholds");
      return null;
    }
    
    // Step 3: Format for Solidity
    console.log("\n📦 Step 3: Formatting proof for Solidity...");
    const solidityProof = {
      a: [proof.pi_a[0], proof.pi_a[1]],
      b: [
        [proof.pi_b[0][1], proof.pi_b[0][0]],
        [proof.pi_b[1][1], proof.pi_b[1][0]]
      ],
      c: [proof.pi_c[0], proof.pi_c[1]],
      input: publicSignals
    };
    
    console.log("✅ Proof formatted for Solidity verifier");
    
    // Step 4: Save to file (optional)
    if (outputFile) {
      const outputPath = path.join(rootDir, outputFile);
      fs.writeFileSync(outputPath, JSON.stringify({
        proof: solidityProof,
        publicSignals: publicSignals,
        input: input
      }, null, 2));
      console.log(`\n💾 Proof saved to: ${outputFile}`);
    }
    
    // Display proof
    console.log("\n📄 Proof Components:");
    console.log(`   pi_a: [${solidityProof.a[0].slice(0, 20)}..., ${solidityProof.a[1].slice(0, 20)}...]`);
    console.log(`   pi_b: [[${solidityProof.b[0][0].slice(0, 15)}..., ...], [...]]`);
    console.log(`   pi_c: [${solidityProof.c[0].slice(0, 20)}..., ${solidityProof.c[1].slice(0, 20)}...]`);
    console.log(`   Public signals: [${publicSignals.join(", ")}]`);
    
    console.log("\n✨ Proof generation complete!");
    console.log("=" .repeat(60));
    
    return solidityProof;
    
  } catch (error) {
    console.error("\n❌ Proof generation failed:", error.message);
    return null;
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  
  // Check if input file provided
  let input;
  if (args[0]) {
    const inputFile = path.join(__dirname, "..", args[0]);
    if (!fs.existsSync(inputFile)) {
      console.error(`❌ Input file not found: ${args[0]}`);
      process.exit(1);
    }
    input = JSON.parse(fs.readFileSync(inputFile));
  } else {
    // Use default valid example
    const exampleFile = path.join(__dirname, "../circuits/input_example.json");
    input = JSON.parse(fs.readFileSync(exampleFile));
  }
  
  const outputFile = args[1] || "proof.json";
  
  await generateProof(input, outputFile);
}

// Allow this script to be imported or run directly
if (require.main === module) {
  main().catch(error => {
    console.error("Error:", error);
    process.exit(1);
  });
}

module.exports = { generateProof };
