# ⚡ Quick Start Guide

Get the MVP running in **4 simple steps**!

## Prerequisites

- ✅ Node.js 18+ installed
- ✅ npm 9+ installed
- ⚠️  Circom compiler ([install guide](https://docs.circom.io/getting-started/installation/))

## Step 1: Install Everything

```bash
# From project root
npm install
cd zk-setup && npm install
cd ../blockchain && npm install
```

## Step 2: Setup Zero-Knowledge System

```bash
cd zk-setup
npm run setup
```

⏱️ **Takes ~5-10 minutes** (downloads 200MB file, runs cryptographic ceremony)

✅ **Success when you see:** `🎉 Zero-Knowledge Proof Setup Complete!`

## Step 3: Deploy Contracts

**Terminal 1:**
```bash
cd blockchain
npm run node
```

**Terminal 2:**
```bash
cd blockchain
npm run deploy:local
```

✅ **Success when you see:** `🎉 DEPLOYMENT COMPLETE!`

## Step 4: Test It!

```bash
cd zk-setup

# Generate a valid proof
npm run generate-proof:valid

# Generate an invalid proof  
npm run generate-proof:invalid
```

✅ **Valid proof should show:** `✅ Proof verified successfully!`  
✅ **Invalid proof should show:** `❌ Proof verification failed!`

---

## 🎉 You're Done!

Your zero-knowledge creditworthiness verification system is now running!

### What You Have:

- ✅ ZK circuit that proves creditworthiness without revealing data
- ✅ Smart contracts deployed to local blockchain
- ✅ Ability to generate and verify cryptographic proofs
- ✅ Non-transferable credential tokens (Soulbound)

### Try These Commands:

```bash
# Generate different proofs
cd zk-setup
node scripts/generateProof.js circuits/input_example.json my_proof.json

# Compile contracts
cd blockchain
npm run compile

# Run Hardhat console
npx hardhat console --network localhost
```

### Interact with Contracts:

```javascript
// In Hardhat console
const Registry = await ethers.getContractFactory("CreditworthinessRegistry");
const registry = await Registry.attach("YOUR_REGISTRY_ADDRESS");

// Check credential count
await registry.credentialIdCounter();

// Query credentials for an address
await registry.getActiveCredentials("0xYOUR_ADDRESS");
```

---

## 🐛 Troubleshooting

**Problem:** `Circom compiler not found`  
**Solution:** Install from https://docs.circom.io/getting-started/installation/

**Problem:** `Groth16Verifier.sol not found`  
**Solution:** Run `cd zk-setup && npm run setup`

**Problem:** `Cannot connect to Hardhat node`  
**Solution:** Make sure `npm run node` is running in a separate terminal

**Problem:** `Powers of Tau download fails`  
**Solution:** Download manually from:  
https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_12.ptau  
Save to: `zk-setup/keys/powersOfTau28_hez_final_12.ptau`

---

## 📚 Learn More

- Read `README.md` for complete documentation
- Read `MVP_COMPLETE.md` for what was built
- Check `MVP_PROGRESS.md` for implementation details
- Read contract comments in `blockchain/contracts/`
- Read circuit comments in `zk-setup/circuits/creditworthiness.circom`

---

**Need help?** Check the full README.md or the detailed documentation!
