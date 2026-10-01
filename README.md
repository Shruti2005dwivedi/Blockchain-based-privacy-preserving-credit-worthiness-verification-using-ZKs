# 🔐 Blockchain-Based Privacy-Preserving Creditworthiness Verification Using Zero-Knowledge Proofs

[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue.svg)](https://soliditylang.org/)
[![Hardhat](https://img.shields.io/badge/Hardhat-Development-yellow.svg)](https://hardhat.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

A decentralized, privacy-preserving creditworthiness verification system that allows borrowers to prove they meet credit criteria **without revealing their actual financial data** using Zero-Knowledge Proofs (ZKPs) and blockchain technology.

## 🌟 Features

- **🔒 Privacy-First**: Financial data never leaves the user's browser
- **🧮 Zero-Knowledge Proofs**: Cryptographically prove eligibility without revealing sensitive information
- **🎫 Soulbound Tokens (SBT)**: Non-transferable credentials bound to the borrower's wallet
- **⛓️ On-Chain Verification**: Transparent and auditable blockchain-based system
- **🌐 Web Dashboard**: User-friendly interface for credential management
- **🛡️ Secure Smart Contracts**: Built with OpenZeppelin libraries and best practices

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Smart Contracts](#smart-contracts)
- [How It Works](#how-it-works)
- [Usage](#usage)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

Traditional credit verification systems require borrowers to disclose sensitive financial information (income, credit scores, debt ratios) to multiple parties, creating privacy risks and potential for data breaches.

**Our Solution**: Using Zero-Knowledge Proofs, borrowers can prove they meet creditworthiness thresholds without revealing their actual financial data. The blockchain provides transparency and auditability, while ZKPs ensure privacy.

### Use Cases

- **Peer-to-Peer Lending**: Borrowers prove creditworthiness to lenders privately
- **DeFi Protocols**: Undercollateralized lending based on verified credentials
- **Credit Scoring**: Portable, privacy-preserving credit history
- **Financial Inclusion**: Access to credit without exposing sensitive data

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      USER BROWSER                            │
│  ┌────────────────┐         ┌──────────────────┐           │
│  │   Dashboard    │◄────────┤   MetaMask       │           │
│  │   (Frontend)   │         │   Wallet         │           │
│  └────────┬───────┘         └──────────────────┘           │
│           │                                                  │
│           │ (Private: Income, Credit Score, Debt Ratio)     │
│           ▼                                                  │
│  ┌────────────────────────────────────┐                    │
│  │   ZK Proof Generator (snarkjs)     │                    │
│  │   • Generates proof locally        │                    │
│  │   • Data NEVER leaves browser      │                    │
│  └────────────────┬───────────────────┘                    │
└───────────────────┼──────────────────────────────────────────┘
                    │ (Proof + Public Signals)
                    ▼
┌─────────────────────────────────────────────────────────────┐
│               BLOCKCHAIN (Ethereum/Hardhat)                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Groth16Verifier → CreditworthinessRegistry → SBT   │  │
│  │  Verify ZK Proof   Issue Credential    Mint Token   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Tech Stack

### Blockchain Layer
- **Solidity** 0.8.24 - Smart contract development
- **Hardhat** - Ethereum development environment
- **OpenZeppelin Contracts** - Secure, audited contract libraries
- **Ethers.js** v5.7.2 - Blockchain interaction

### Zero-Knowledge Layer
- **Circom** 2.x - ZK circuit compiler
- **snarkjs** - ZK proof generation & verification
- **Groth16** - Efficient ZK proof system

### Frontend
- **HTML5/CSS3/JavaScript** - Web interface
- **Ethers.js** - Wallet integration
- **MetaMask** - Ethereum wallet

## 🚀 Getting Started

### Prerequisites

```bash
Node.js >= 18.0.0
npm >= 9.0.0
MetaMask browser extension
Circom compiler (for ZK proofs)
```

### Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/Shruti2005dwivedi/Blockchain-based-privacy-preserving-credit-worthiness-verification-using-ZKs.git
cd Blockchain-based-privacy-preserving-credit-worthiness-verification-using-ZKs
```

2. **Install dependencies**
```bash
npm install
cd blockchain && npm install
cd ../zk-setup && npm install
```

3. **Start local blockchain**
```bash
cd blockchain
npm run node
```

4. **Deploy contracts** (in new terminal)
```bash
cd blockchain
npm run deploy:local
```

5. **Start web dashboard** (in new terminal)
```bash
cd frontend
node server.js
```

6. **Open browser**
```
http://localhost:3000
```

### MetaMask Configuration

**Add Hardhat Local Network:**
- Network Name: `Hardhat Local`
- RPC URL: `http://127.0.0.1:8545`
- Chain ID: `31337`
- Currency: `ETH`

**Import Test Account** (10,000 ETH):
```
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## 📁 Project Structure

```
.
├── blockchain/                 # Smart Contracts & Deployment
│   ├── contracts/
│   │   ├── CreditworthinessRegistry.sol
│   │   ├── CredentialSBT.sol
│   │   └── Groth16Verifier.sol
│   ├── scripts/
│   │   └── deploy.ts
│   ├── test/
│   └── hardhat.config.ts
│
├── frontend/                   # Web Dashboard
│   ├── index.html
│   └── server.js
│
├── zk-setup/                   # Zero-Knowledge Proofs
│   ├── circuits/
│   │   └── creditworthiness.circom
│   ├── scripts/
│   │   ├── setup.js
│   │   └── generateProof.js
│   └── keys/                   # Generated after setup
│
├── backend/                    # API Server (Future)
│
├── docs/                       # Documentation
│   ├── QUICK_START.md
│   ├── PROJECT_OVERVIEW.md
│   └── RUNNING_STATUS.md
│
└── README.md
```

## 📜 Smart Contracts

### CreditworthinessRegistry.sol
Central registry managing credential lifecycle:
- ✅ Credential issuance with ZK proof verification
- ✅ State management (VERIFIED, EXPIRED, REVOKED)
- ✅ Role-based access control
- ✅ Event emission for transparency

### CredentialSBT.sol
Non-transferable credential tokens (Soulbound):
- ✅ ERC721-based implementation
- ✅ Transfer prevention (soulbound property)
- ✅ Registry-only minting
- ✅ Burn functionality

### Groth16Verifier.sol
Zero-knowledge proof verifier:
- ✅ Groth16 proof verification
- ✅ On-chain validation
- ⚠️ Currently in mock mode (accepts all proofs for testing)

## 🔄 How It Works

### Step 1: Data Input (Browser)
User enters private financial data:
- Annual Income: $75,000
- Credit Score: 750
- Debt-to-Income Ratio: 25%

### Step 2: ZK Proof Generation (Browser)
snarkjs generates cryptographic proof that:
- Income ≥ $50,000 ✓
- Credit Score ≥ 700 ✓
- Payment Ratio ≤ 30% ✓

**WITHOUT revealing actual values!**

### Step 3: Blockchain Submission
Transaction sent with:
- ZK Proof (cryptographic data)
- Public Signals (thresholds only)
- Policy ID
- Expiration period

### Step 4: Smart Contract Verification
1. Registry calls `Groth16Verifier.verifyProof()`
2. If valid → Create credential record
3. Call `CredentialSBT.mint()` for borrower
4. Emit `CredentialIssued` event

### Step 5: Credential Issued
Borrower receives:
- ✅ Credential Record (on-chain)
- ✅ SBT Token (non-transferable)
- ✅ Proof of creditworthiness

Lenders can verify **WITHOUT seeing actual values!**

## 💻 Usage

### Submit a Credential

1. Connect MetaMask wallet
2. Enter financial data in the dashboard
3. Click "Submit Credential"
4. Confirm transaction in MetaMask
5. Wait for confirmation (~30 seconds)

### Verify a Credential (as Lender)

```javascript
// In Hardhat console or script
const registry = await ethers.getContractAt("CreditworthinessRegistry", REGISTRY_ADDRESS);

// Check if credential is valid
const isValid = await registry.isCredentialValid(credentialId);

// Get credential details (thresholds only, no private data)
const credential = await registry.getCredential(credentialId);
```

### Revoke a Credential (as Issuer)

```javascript
// Must have ISSUER_ROLE
await registry.revokeCredential(credentialId, "Reason for revocation");
```

## 🧪 Testing

### Run Contract Tests
```bash
cd blockchain
npx hardhat test
```

### Run Integration Test
```bash
cd blockchain
npx hardhat run test-credential.js --network localhost
```

### Test ZK Proof Generation
```bash
cd zk-setup
npm run generate-proof:valid
npm run generate-proof:invalid
```

## 🚢 Deployment

### Deploy to Local Network
```bash
cd blockchain
npm run node              # Terminal 1
npm run deploy:local      # Terminal 2
```

### Deploy to Testnet (Sepolia)
```bash
# Set environment variables in .env
SEPOLIA_RPC_URL=your_rpc_url
PRIVATE_KEY=your_private_key

# Deploy
npm run deploy:sepolia
```

### Deploy to Mainnet
```bash
# ⚠️ WARNING: Real money involved!
npm run deploy:mainnet
```

## 📊 Contract Addresses

### Local Network (Hardhat)
- **Registry**: `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`
- **SBT**: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`
- **Verifier**: `0x5FbDB2315678afecb367f032d93F642f64180aa3`

### Testnet (Sepolia)
- Coming soon...

### Mainnet
- Not deployed yet

## 🔐 Security

### Current Status
- ✅ Smart contracts follow best practices
- ✅ OpenZeppelin libraries used
- ✅ ReentrancyGuard implemented
- ⚠️ ZK Verifier in mock mode (testing only)

### Before Production
- [ ] Complete ZK proof system setup
- [ ] Security audit of all contracts
- [ ] Gas optimization analysis
- [ ] Comprehensive testing suite
- [ ] Bug bounty program

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Solidity style guide
- Write comprehensive tests
- Document all functions
- Run linter before committing

## 📚 Documentation

- [Quick Start Guide](docs/QUICK_START.md)
- [Project Overview](docs/PROJECT_OVERVIEW.md)
- [Running Status](docs/RUNNING_STATUS.md)
- [API Documentation](docs/API.md) (Coming soon)

## 🗺️ Roadmap

### Phase 1: MVP ✅
- [x] Smart contract development
- [x] Web dashboard
- [x] Basic ZK circuit
- [x] Local deployment

### Phase 2: ZK Integration ⚠️
- [ ] Install Circom compiler
- [ ] Compile ZK circuits
- [ ] Generate proving keys
- [ ] Real proof verification

### Phase 3: Backend API
- [ ] Express API server
- [ ] PostgreSQL database
- [ ] Event indexing
- [ ] Caching layer

### Phase 4: Production
- [ ] Testnet deployment
- [ ] Security audit
- [ ] Mainnet deployment
- [ ] Mobile app

## ❓ FAQ

**Q: Is my financial data stored on the blockchain?**  
A: No! Only the cryptographic proof and thresholds are stored on-chain. Your actual income and credit score never leave your browser.

**Q: Can I transfer my credential to someone else?**  
A: No, credentials are Soulbound Tokens (SBT) and cannot be transferred. They're permanently bound to your wallet.

**Q: How long is a credential valid?**  
A: Credentials have configurable expiration periods (default: 90 days). After expiration, they become invalid.

**Q: What if my credential is issued incorrectly?**  
A: Authorized issuers can revoke credentials with a reason. Revocation is permanent and recorded on-chain.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) - Secure smart contract libraries
- [Circom](https://docs.circom.io/) - ZK circuit compiler
- [snarkjs](https://github.com/iden3/snarkjs) - ZK proof generation
- [Hardhat](https://hardhat.org/) - Ethereum development environment

## 📧 Contact

**Shruti Dwivedi**
- GitHub: [@Shruti2005dwivedi](https://github.com/Shruti2005dwivedi)
- Project Link: [https://github.com/Shruti2005dwivedi/Blockchain-based-privacy-preserving-credit-worthiness-verification-using-ZKs](https://github.com/Shruti2005dwivedi/Blockchain-based-privacy-preserving-credit-worthiness-verification-using-ZKs)

## ⭐ Star History

If you find this project useful, please consider giving it a star!

---

**Built with ❤️ for privacy and financial inclusion**
