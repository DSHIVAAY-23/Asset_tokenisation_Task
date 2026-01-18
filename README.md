# Xaults Upgradeable Asset Tokenizer

A UUPS-upgradeable ERC20 token implementation for tokenized financial assets, built with Foundry and OpenZeppelin Contracts Upgradeable.

## Overview

This project implements a secure, upgradeable smart contract system for representing tokenized financial assets. The implementation uses the UUPS (Universal Upgradeable Proxy Standard) pattern to enable contract logic evolution while preserving state.

### Architecture

```
┌─────────────────┐
│  ERC1967Proxy   │  ← All interactions
└────────┬────────┘
         │ delegatecall
         ▼
┌─────────────────┐
│  AssetToken V1  │  ← Implementation
│  (or V2)        │
└─────────────────┘
```

## Features

### AssetToken V1
- ERC20 token with standard functionality
- Role-based access control (Admin and Minter roles)
- Supply cap enforcement (1M tokens max)
- UUPS upgradeability
- Custom error handling for gas efficiency

### AssetTokenV2
- All V1 features
- Pausable transfers
- Storage-compatible with V1

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

## Setup

```bash
# Install dependencies
forge install

# Build contracts
forge build
```

## Testing

The test suite validates the complete upgrade lifecycle:

```bash
# Run all tests
forge test

# Run with detailed output
forge test -vvv

# Run specific test
forge test --match-test testUpgradePreservesState -vvv

# Generate gas report
forge test --gas-report
```

### Test Coverage

The suite includes 11 comprehensive tests covering:
- Token minting and balance management
- Max supply enforcement
- Access control for minting and upgrades
- UUPS upgrade mechanism
- State persistence across upgrades
- V2 pause functionality

## Deployment

### Local Testnet (Anvil)

```bash
# Start Anvil
anvil

# Deploy (in new terminal)
forge script script/DeployAssetToken.s.sol:DeployAssetToken \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Sepolia Testnet

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export SEPOLIA_RPC_URL=your_rpc_url
export ETHERSCAN_API_KEY=your_api_key

# Deploy with verification
forge script script/DeployAssetToken.s.sol:DeployAssetToken \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## CLI Interaction

After deployment, interact with the contract using `cast`:

```bash
# Set proxy address
export PROXY=<deployed_proxy_address>

# Check token details
cast call $PROXY "name()(string)" --rpc-url http://localhost:8545
cast call $PROXY "symbol()(string)" --rpc-url http://localhost:8545
cast call $PROXY "maxSupply()(uint256)" --rpc-url http://localhost:8545

# Mint tokens (requires MINTER_ROLE)
cast send $PROXY "mint(address,uint256)" \
  <recipient_address> \
  100000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# Check balance
cast call $PROXY "balanceOf(address)(uint256)" <address> --rpc-url http://localhost:8545

# Transfer tokens
cast send $PROXY "transfer(address,uint256)" \
  <recipient_address> \
  50000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

## Storage Layout Safety

### Verification Process

Storage layout compatibility was verified using Foundry's inspection tools:

```bash
# Check V1 storage layout
forge inspect src/AssetToken.sol:AssetToken storage-layout

# Check V2 storage layout
forge inspect src/AssetTokenV2.sol:AssetTokenV2 storage-layout
```

### Layout Comparison

**AssetToken V1:**
```
| Name       | Type    | Slot | Offset | Bytes |
|------------|---------|------|--------|-------|
| _maxSupply | uint256 | 0    | 0      | 32    |
```

**AssetTokenV2:**
```
| Name       | Type    | Slot | Offset | Bytes |
|------------|---------|------|--------|-------|
| _maxSupply | uint256 | 0    | 0      | 32    |
```

The storage layouts are identical. V2 inherits from V1 and adds `PausableUpgradeable`, which uses its own storage namespace. No storage conflicts occur.

### Safety Rules

1. Never change the order of existing state variables
2. Never change the type of existing state variables
3. Never remove existing state variables
4. New variables can be added at the end
5. Inherited contracts add storage in inheritance order

## Project Structure

```
.
├── foundry.toml              # Foundry configuration
├── src/
│   ├── AssetToken.sol        # V1 implementation
│   └── AssetTokenV2.sol      # V2 implementation
├── script/
│   └── DeployAssetToken.s.sol # Deployment script
├── test/
│   └── AssetToken.t.sol      # Test suite
└── README.md
```

## Security Considerations

- UUPS pattern: Upgrade logic resides in implementation; `_authorizeUpgrade` is protected
- Role management: Only trusted addresses should have admin/minter roles
- Supply cap: Immutable once set during initialization
- Pause power: Admin can pause transfers in V2
- Storage safety: Always verify layout compatibility before upgrades

## License

MIT
