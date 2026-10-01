# Zero-Knowledge Proof Setup

This directory contains the Circom circuit for creditworthiness verification and the trusted setup artifacts.

## Prerequisites

1. **Install Circom Compiler**:
   ```bash
   # Download from https://docs.circom.io/getting-started/installation/
   # Or use cargo:
   cargo install --git https://github.com/iden3/circom.git circom
   ```

2. **Install snarkjs** (already in package.json):
   ```bash
   npm install
   ```

## Directory Structure

- `circuits/` - Circom circuit files
- `build/` - Compiled circuit artifacts (R1CS, WASM, symbols)
- `keys/` - Proving and verification keys
- `contracts/` - Generated Solidity verifier contract

## Setup Process

1. **Compile Circuit**:
   ```bash
   npm run compile
   ```

2. **Run Trusted Setup**:
   ```bash
   npm run setup
   ```

3. **Generate Verifier Contract**:
   ```bash
   npm run generate-verifier
   ```

## Notes

- The Powers of Tau ceremony file (ptau) will be downloaded during setup
- All cryptographic keys are stored in the `keys/` directory
- The Groth16Verifier.sol contract should be copied to `../blockchain/contracts/`
