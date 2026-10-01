# 🚀 Project Running Status

## ✅ Currently Running

### Blockchain Node
- **Status**: ✅ RUNNING
- **Network**: Hardhat Local Network
- **URL**: http://127.0.0.1:8545/
- **Chain ID**: 31337

### Deployed Contracts

| Contract | Address | Status |
|----------|---------|--------|
| **Groth16Verifier** | `0x5FbDB2315678afecb367f032d93F642f64180aa3` | ✅ Deployed |
| **CredentialSBT** | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | ✅ Deployed |
| **CreditworthinessRegistry** | `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` | ✅ Deployed |

### Test Accounts (Available with 10,000 ETH each)

| Account | Address | Private Key |
|---------|---------|-------------|
| **Account #0** | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` |
| **Account #1** | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` |
| **Account #2** | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a8804cdab365a` |

⚠️ **WARNING**: These accounts are publicly known. Never use them on mainnet or send real funds!

---

## ⚠️ Known Limitations

### ZK Proof System - NOT READY
- **Status**: ❌ NOT CONFIGURED
- **Reason**: Circom compiler not installed
- **Impact**: The Groth16Verifier is currently using a **MOCK implementation** that always returns `true`
- **Security**: ⚠️ **DO NOT USE IN PRODUCTION** - All proofs will be accepted as valid!

### What This Means
- ✅ You can deploy and interact with contracts
- ✅ You can test the contract architecture and functions
- ✅ You can develop the frontend/backend integration
- ❌ Real zero-knowledge proofs will not be verified
- ❌ Cannot generate real cryptographic proofs yet

---

## 🔧 To Get Full ZK Functionality

### Install Circom Compiler

**Option 1: Windows with Visual Studio Build Tools**
```powershell
# 1. Install Visual Studio Build Tools 2022
# Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
# Select "Desktop development with C++" workload during installation

# 2. After installation, open a new terminal and run:
cd %TEMP%
git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom

# 3. Verify installation
circom --version
```

**Option 2: Using WSL (Windows Subsystem for Linux)**
```bash
# In WSL Ubuntu terminal:
sudo apt update
sudo apt install -y build-essential
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
cargo install circom
```

### Run ZK Setup

Once Circom is installed:
```bash
cd blockchain-zkp-creditworthiness/zk-setup
npm run setup
```

This will:
- Download Powers of Tau file (~200MB)
- Compile the circom circuit
- Generate proving and verification keys
- Create the real Groth16Verifier.sol contract
- Copy it to the blockchain/contracts folder

Then redeploy:
```bash
cd ../blockchain
npm run deploy:local
```

---

## 🧪 What You Can Test Now

### 1. Contract Interactions

```bash
cd blockchain-zkp-creditworthiness/blockchain
npx hardhat console --network localhost
```

Then in the console:
```javascript
// Get deployed contracts
const Registry = await ethers.getContractFactory("CreditworthinessRegistry");
const registry = await Registry.attach("0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");

const SBT = await ethers.getContractFactory("CredentialSBT");
const sbt = await SBT.attach("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512");

// Check if issuer is authorized (deployer is admin)
const [deployer] = await ethers.getSigners();
await registry.isAuthorizedIssuer(deployer.address);

// Mock proof submission (will pass with mock verifier)
const a = [1, 2];
const b = [[1, 2], [3, 4]];
const c = [5, 6];
const publicSignals = [50000, 700, 30]; // minIncome, minCreditScore, minPaymentRatio
const policyId = 1;
const expirationDays = 90;

const tx = await registry.submitCredential(a, b, c, publicSignals, policyId, expirationDays);
await tx.wait();

// Check credential
const credentialId = await registry.credentialIdCounter();
const credential = await registry.getCredential(credentialId);
console.log(credential);

// Check SBT balance
const balance = await sbt.balanceOf(deployer.address);
console.log("SBT Balance:", balance.toString());
```

### 2. Develop Frontend/Backend

You can now:
- Connect Web3 wallet to `http://127.0.0.1:8545`
- Build UI for credential submission
- Test contract interaction flows
- Develop API endpoints

### 3. Test Contract Logic

```bash
# Run contract tests
cd blockchain-zkp-creditworthiness/blockchain
npx hardhat test --network localhost
```

---

## 📊 System Requirements Status

| Component | Required | Installed | Status |
|-----------|----------|-----------|--------|
| Node.js 18+ | ✅ | v24.14.1 | ✅ |
| npm 9+ | ✅ | ✅ | ✅ |
| Hardhat | ✅ | ✅ | ✅ |
| Rust/Cargo | ⚠️ | v1.98.1 | ✅ |
| Circom | ⚠️ | ❌ | ❌ |
| Visual Studio Build Tools | ⚠️ | ❌ | ❌ |

---

## 🛑 How to Stop

### Stop Blockchain Node
The Hardhat node is running in the background. To stop it:
- Close this Kiro session, or
- Manually stop the process

### Clean Restart
```bash
# Kill all node processes (if needed)
taskkill /F /IM node.exe

# Restart from scratch
cd blockchain-zkp-creditworthiness/blockchain
npm run node  # In one terminal
npm run deploy:local  # In another terminal
```

---

## 📚 Additional Resources

- [Circom Installation Guide](https://docs.circom.io/getting-started/installation/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [snarkjs Documentation](https://github.com/iden3/snarkjs)

---

**Last Updated**: September 28, 2026
**Project Status**: Development Mode (Mock ZK Verifier Active)
