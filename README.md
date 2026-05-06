# CipherID — Private Identity Protocol

> **Zama Developer Program Season 2 Submission**
> Private KYC attestations powered by Fully Homomorphic Encryption (FHE) on Ethereum.

🌐 **Live Demo:** https://cipherid-protocol.vercel.app
📄 **Contract:** [0x5124338fb3eaBC0661c812873F16321f616E134D](https://sepolia.etherscan.io/address/0x5124338fb3eaBC0661c812873F16321f616E134D)
🔗 **Network:** Sepolia Testnet

---

## The Problem

Every DeFi protocol that needs KYC faces an impossible tradeoff:

- **Do KYC on-chain** → user identity becomes fully public, anyone can track verified wallets
- **Skip KYC** → regulators shut you down, institutions won't participate
- **Use off-chain KYC** → centralized honeypot, users must trust a middleman

**CipherID eliminates this tradeoff.**

---

## What We Built

CipherID is a private on-chain KYC attestation registry where:

- KYC providers write **encrypted attestations** for verified users
- dApps query **"does this address pass KYC?"** and get a yes/no
- The KYC tier, compliance score, jurisdiction, and expiry **stay encrypted forever**
- Not even the contract owner can read individual user data
- Built entirely on **Zama FHEVM** — Fully Homomorphic Encryption on EVM

---

## 12 FHE-Native Features

### 1. 🔒 Encrypted Tier Comparison
FHE `ge()` operation on encrypted `euint8`. The comparison result stays encrypted — only the Zama KMS gateway can reveal the boolean outcome.

### 2. 🏛 Multi-Provider Consensus
Require N-of-M KYC providers to agree before an attestation is finalized. Individual provider votes are stored as encrypted `euint8` values — only the consensus outcome is public.

### 3. ⏱ Encrypted KYC Expiry
Expiry timestamps stored as encrypted `euint32`. No chain scanner can see when wallets expire and front-run renewals. Comparison with `block.timestamp` happens entirely in FHE.

### 4. 🌍 Private Jurisdiction Enforcement
Jurisdiction codes stored encrypted. Protocols can enforce sanctions and regional compliance without publishing which jurisdictions are blocked. Users learn only pass/fail.

### 5. ⇢ Attestation Delegation
Verified EOAs can delegate their KYC status to contract wallets (Safe, multisig) without any public on-chain link between the two addresses. Solves the institutional wallet problem.

### 6. ◎ Encrypted Compliance Score (0-255)
A full compliance score stored as encrypted `euint8`. Each protocol sets its own threshold privately — one attestation serves infinite protocols with different requirements.

### 7. ⬟ Soulbound Identity Badges
Non-transferable NFT-like badges auto-minted on attestation. Badge metadata (tier, score) stays encrypted. Visible on-chain but unreadable without user permission.

### 8. ▲ Provider Leaderboard
Public accountability stats — attestation count, revocation rate, earnings — without revealing who was attested. Providers compete on performance without compromising user privacy.

### 9. 💰 Pay-Per-Query Marketplace
dApps pay a fee per verification query. Fees go directly to the attesting provider. First on-chain KYC marketplace where providers earn for their compliance work.

### 10. ⊛ Regulatory Audit Trail
Every attestation, revocation, delegation, and query is logged on-chain. Only the designated regulator address can read entries. Satisfies AML audit requirements without public exposure.

### 11. ❄ Emergency Freeze Module
Owner can freeze the entire protocol or individual wallets instantly. All `meetsMinTier()` calls return blocked during freeze. Critical for regulatory compliance and incident response.

### 12. ⊕ Protocol Integration Registry
dApps register themselves and track query volume and fees paid. One modifier makes any Solidity contract KYC-compliant. Composable primitive for the entire ecosystem.

---

## Architecture
┌─────────────────────────────────────────────────────────┐
│                    CipherID Protocol                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  KYC Provider          User Wallet         dApp         │
│      │                     │                │           │
│      │  issueAttestation() │                │           │
│      │──────────────────→  │                │           │
│      │                     │                │           │
│      │   Encrypted euint8  │                │           │
│      │   stored on-chain   │                │           │
│      │                     │                │           │
│      │                     │  meetsMinTier()│           │
│      │                     │ ←──────────────│           │
│      │                     │                │           │
│      │              FHE ge() on             │           │
│      │              encrypted data          │           │
│      │                     │                │           │
│      │              ebool result            │           │
│      │              (encrypted)             │           │
│      │                     │──────────────→ │           │
│      │                     │                │           │
│                  Zama KMS Gateway                       │
│                  decrypts only for                      │
│                  authorized caller                      │
└─────────────────────────────────────────────────────────┘

---

## Smart Contract

**File:** `contracts/ConfidentialKYC.sol`
**Deployed:** Sepolia Testnet
**Address:** `0x5124338fb3eaBC0661c812873F16321f616E134D`

### Key Functions

| Function | Description |
|----------|-------------|
| `issueAttestationPlaintext()` | Provider issues encrypted KYC attestation |
| `meetsMinTier(address, uint8)` | Returns encrypted boolean — does user meet tier? |
| `queryWithFee(address, uint8)` | Pay-per-query marketplace verification |
| `submitConsensusVote(address, uint8)` | Multi-provider encrypted vote |
| `delegateAttestation(address)` | Delegate verified status to contract wallet |
| `freezeProtocol()` | Emergency protocol halt |
| `getAuditEntry(uint256)` | Regulator-only audit log access |
| `registerIntegration(string)` | Protocol registry entry |
| `getBadge(address)` | Soulbound badge lookup |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| FHE Library | Zama FHEVM (`fhevm/lib/TFHE.sol`) |
| Smart Contract | Solidity 0.8.24 |
| Development | Hardhat + TypeScript |
| Frontend | React + Vite + TypeScript |
| Web3 | ethers.js v6 |
| Deployment | Vercel |
| Network | Ethereum Sepolia Testnet |

---

## Real-World Use Cases

**Compliant DeFi** — DEXs and lending protocols gate access to verified users without storing identity data.

**RWA Token Sales** — Tokenized T-bills and real estate legally require accredited investor checks. Tier 2 handles this privately.

**Institutional On-Ramps** — Banks verify wallets privately. DeFi protocols check compliance without seeing underlying data.

**Cross-Protocol Identity** — One KYC, every protocol. Users verify once and reuse across the entire ecosystem.

**DAO Governance Gating** — Restrict votes to verified humans without creating a public member list.

**Airdrop Compliance** — Exclude sanctioned addresses without publishing a public blacklist.

---

## Project Structure
cipherid/
├── contracts/
│   └── ConfidentialKYC.sol     # Main CipherID contract
├── scripts/
│   └── deploy.ts               # Deployment script
├── test/
│   └── ConfidentialKYC.ts      # Test suite (7 passing)
└── confidential-kyc-frontend/
├── src/
│   ├── App.tsx              # Full React application
│   ├── App.css              # Styling
│   └── abi/
│       └── ConfidentialKYC.json  # Contract ABI
└── .env                    # Contract address config

---

## Running Locally

### Prerequisites
- Node.js v22+
- MetaMask with Sepolia ETH

### Smart Contract
```bash
git clone https://github.com/mestarkris/cipherid.git
cd cipherid
npm install
npx hardhat vars set MNEMONIC
npx hardhat vars set INFURA_API_KEY
npx hardhat compile
npx hardhat test
npx hardhat run scripts/deploy.ts --network sepolia
```

### Frontend
```bash
cd confidential-kyc-frontend
npm install
echo "VITE_CONTRACT_ADDRESS=0x5124338fb3eaBC0661c812873F16321f616E134D" > .env
npm run dev
```

Open `http://localhost:5173` and connect MetaMask on Sepolia.

---

## Test Results
CipherID
✔ should deploy and set owner correctly
✔ should add a KYC provider
✔ should remove a KYC provider
✔ should reject provider management from non-owner
✔ should reject attestation from non-approved provider
✔ should revert meetsMinTier if no attestation
✔ should revert revokeAttestation if not authorized
7 passing (287ms)

---

## Why FHE Over ZK?

| Feature | ZK Proofs | FHE (CipherID) |
|---------|-----------|----------------|
| Compute on encrypted data | ❌ | ✅ |
| Multi-party data combination | ❌ | ✅ |
| Updatable encrypted state | ❌ | ✅ |
| On-chain encrypted storage | ❌ | ✅ |
| Arbitrary comparisons | Limited | ✅ |

ZK proofs verify a statement was true at a point in time. FHE lets you **compute on the encrypted data itself** — enabling dynamic compliance checks, score comparisons, and multi-provider consensus that ZK cannot do.

---

## Hackathon

**Competition:** Zama Developer Program Season 2
**Track:** Builder
**Theme:** Confidential Finance
**Submission Date:** May 2026

---

## License

MIT

---

*Built with ❤️ using Zama FHEVM — making compliant DeFi possible without sacrificing privacy.*
