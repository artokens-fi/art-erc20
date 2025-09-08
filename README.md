# ARTokens

## Overview

ARTokens onboard real-world asset value on-chain with fully backed, MiCA-compliant Asset-referenced tokens, built on **BNB Smart Chain (BSC)** and compatible with other EVM networks.

The aRToken contract is a comprehensive ERC20 token implementation that represents an Asset Reference Token (ART).

## Technology Stack

- **Blockchain**: BNB Smart Chain + EVM-compatible chains
- **Smart Contracts**: Solidity 0.8.30
- **Frontend**: Next.js + ethers.js
- **Development**: Foundry, OpenZeppelin libraries

## Compatibility

The aRToken contract is compatible with EVM based blockchains such as Ethereum, Base and BSC (BNB Smart Chain).

## Currently Supported Networks

- **BNB Smart Chain Mainnet** (Chain ID: 56)
- **BNB Smart Chain Testnet** (Chain ID: 97)

## Contract Addresses

| Network     | Core Contract                              | Token Contract                             | (Optional: Vault / Router / Governance) |
| ----------- | ------------------------------------------ | ------------------------------------------ | --------------------------------------- |
| BNB Mainnet | 0x782ba6e3048f014a34f14744e8ba98b32125c215 | 0x782ba6e3048f014a34f14744e8ba98b32125c215 |                                         |
| BNB Testnet | 0x782ba6e3048f014a34f14744e8ba98b32125c215 | 0x782ba6e3048f014a34f14744e8ba98b32125c215 |                                         |

## Project Features

- Security of administrative roles and functions
- Backed by real-world assets
- Fully permissionless, transparent and tradeable tokens

## Smart Contract Details

### Roles

- **DEFAULT_ADMIN_ROLE**: Can manage all roles and has administrative privileges
- **MINTER_ROLE**: Authorized to mint new tokens
- **BURNER_ROLE**: Authorized to burn tokens

### Security Features

- Role separation: Minter and burner roles cannot be assigned to the same address
- Minimum admin transfer delay for enhanced security
- Zero address validation
- Amount validation for all operations

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Ethereum development toolkit

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd art-erc20
```

2. Install dependencies:

```bash
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

## Usage

### Deployment

The contract constructor requires the following parameters:

```solidity
constructor(
    address initialAdmin,      // Initial admin address
    string memory name_,       // Token name
    string memory symbol_,     // Token symbol
    uint8 decimals_,          // Number of decimals
    address minter,           // Initial minter address
    address burner,           // Initial burner address
    uint48 adminTransferDelay // Admin transfer delay (minimum 1 day)
)
```

### Key Functions

- `mint(address to, uint256 amount)` - Mint tokens (MINTER_ROLE required)
- `burn(uint256 amount)` - Burn tokens from caller's balance (BURNER_ROLE required)
- `burnFrom(address account, uint256 amount)` - Burn tokens from account with allowance (BURNER_ROLE required)

## Documentation

Detailed contract documentation is available in [docs/aRToken.md](docs/aRToken.md).

## Copyright

Copyright (c) 2025 ARTokens GmbH
