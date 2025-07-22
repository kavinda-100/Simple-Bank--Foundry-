# Bank System Deployment Guide

## Recommended Deployment Method

The **preferred way** to deploy the complete Bank system is using the comprehensive `DeployBankSystem` script:

```bash
forge script script/DeployBankSystem.s.sol:DeployBankSystem --fork-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

This script:

- Deploys both `BankAccount` and `Bank` contracts
- Automatically grants admin role to the Bank contract
- Provides a complete deployment summary
- Ensures all permissions are set correctly

## Local Development with Anvil

For local testing and development:

```bash
# Start anvil
anvil

# Deploy complete system to local network
forge script script/DeployBankSystem.s.sol:DeployBankSystem --fork-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

## Environment Variables

Create a `.env` file in your project root:

```env
RPC_URL=your_rpc_url_here
PRIVATE_KEY=your_private_key_here
```

Then source it before deployment:

```bash
source .env
```

## Testing

All unit tests use the `DeployBankSystem` script for consistent deployments:

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/unit/BorrowAndPayTest.t.sol

# Run with verbosity
forge test -vv
```

## Important Notes

- ✅ **Use `DeployBankSystem.s.sol`** for production deployments
- ✅ The deployment script automatically handles all admin role permissions
- ✅ All tests are configured to use the comprehensive deployment script
- ✅ No manual permission setup required after deployment
