# 🏦 Simple Bank - Makefile Guide

This comprehensive Makefile provides all the commands you need to test, build, deploy, and interact with your Simple Bank smart contracts.

## 📋 Quick Start

```bash
# See all available commands
make help

# Run all tests
make test

# Deploy to local development network
make deploy-local
```

## 🧪 Testing Commands

### Basic Testing

```bash
# Run all tests
make test

# Run tests with verbose output
make test-v

# Run tests with gas reporting
make test-gas

# Generate coverage report
make coverage
```

### Test by Category

```bash
# Run only unit tests (101 tests)
make test-unit

# Run only fuzz tests (5 tests)
make test-fuzz

# Run only invariant tests (7 tests)
make test-invariant

# Run only integration tests (5 tests)
make test-integration
```

### Specific Test Files

```bash
# Test Bank contract specifically
make test-bank

# Test BankAccount contract specifically
make test-account

# Test borrowing functionality
make test-borrow
```

## 🏗️ Build Commands

```bash
# Build the project
make build

# Clean build artifacts
make clean

# Install dependencies
make install

# Update dependencies
make update

# Format code
make format

# Check contract sizes
make size
```

## 🚀 Deployment Commands

### Local Development

1. **Start Local Network**:

   ```bash
   # Start Anvil in one terminal
   make anvil
   ```

2. **Deploy to Local Network**:

   ```bash
   # In another terminal
   make deploy-local
   ```

3. **Simulate Deployment** (dry run):

   ```bash
   make simulate-deploy
   ```

### Testnet Deployment

1. **Setup Environment Variables**:

   ```bash
   # Copy example environment file
   cp .env.example .env
   
   # Edit with your values
   nano .env
   ```

2. **Deploy to Sepolia Testnet**:

   ```bash
   export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
   export PRIVATE_KEY="0xYOUR_PRIVATE_KEY"
   make deploy-sepolia
   ```

3. **Deploy to Goerli Testnet**:

   ```bash
   export GOERLI_RPC_URL="https://eth-goerli.g.alchemy.com/v2/YOUR_KEY"
   export PRIVATE_KEY="0xYOUR_PRIVATE_KEY"
   make deploy-goerli
   ```

### Mainnet Deployment

⚠️ **WARNING**: Mainnet deployment costs real ETH!

```bash
export MAINNET_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
export PRIVATE_KEY="0xYOUR_PRIVATE_KEY"
make deploy-mainnet
```

## 🔍 Contract Interaction Commands

### Check Balances

```bash
# Check ETH balance of an address
make balance ADDRESS=0x1234567890123456789012345678901234567890
```

### Call Contract Functions

```bash
# Call a read-only function
make call CONTRACT=0xCONTRACT_ADDRESS FUNCTION="getBalance(address)" ARGS=0xUSER_ADDRESS

# Example: Check bank balance
make call CONTRACT=0xYourBankContract FUNCTION="getBalance(address)" ARGS=0xUserAddress
```

### Send Transactions

```bash
# Send a transaction
make send CONTRACT=0xCONTRACT_ADDRESS FUNCTION="deposit()" PRIVATE_KEY=0xYOUR_KEY

# Send ETH to an address
make send-eth TO=0xRECIPIENT_ADDRESS AMOUNT=1ether PRIVATE_KEY=0xYOUR_KEY
```

## 📊 Analysis Commands

### Gas Analysis

```bash
# Generate gas snapshot
make snapshot

# Compare gas changes
make snapshot-diff
```

### Contract Analysis

```bash
# View storage layout
make storage

# Get contract ABI
make abi-bank
make abi-account
```

## 🔧 Utility Commands

### Development Tools

```bash
# Start Anvil with custom settings
make anvil-custom

# Format code and check formatting
make format
make format-check

# Generate documentation
make docs
```

## 📝 Environment Variables

### Required for Testnet/Mainnet

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
GOERLI_RPC_URL=https://eth-goerli.g.alchemy.com/v2/YOUR_KEY
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
```

### Optional for Interaction

```bash
CONTRACT=0xCONTRACT_ADDRESS
FUNCTION="functionName()"
ARGS=argument_value
ADDRESS=0xADDRESS_TO_CHECK
TO=0xRECIPIENT_ADDRESS
AMOUNT=1ether
```

## 🛡️ Security Best Practices

### Private Key Management

- **Never** commit real private keys to version control
- Use different keys for different networks
- Keep mainnet keys extra secure
- Consider hardware wallets for mainnet

### Testing Before Deployment

1. Test on local network first: `make deploy-local`
2. Test on testnet: `make deploy-sepolia`
3. Run full test suite: `make test`
4. Check gas usage: `make test-gas`
5. Only then consider mainnet deployment

### Verification

Always verify your contracts after deployment:

```bash
# Verification is included in deployment commands
make deploy-sepolia  # Includes verification
```

## 🏛️ Complete Workflow Example

Here's a complete workflow from development to deployment:

### 1. Development Phase

```bash
# Install dependencies
make install

# Run tests during development
make test-v

# Check specific functionality
make test-bank
make test-fuzz

# Generate coverage report
make coverage

# Format code
make format
```

### 2. Local Testing

```bash
# Start local network
make anvil

# Deploy locally (in another terminal)
make deploy-local

# Interact with local deployment
make balance ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### 3. Testnet Deployment

```bash
# Setup environment
cp .env.example .env
# Edit .env with your testnet RPC and private key

# Deploy to testnet
make deploy-sepolia

# Test on testnet
make balance ADDRESS=0xYourDeployedContract
```

### 4. Mainnet Deployment (when ready)

```bash
# Final checks
make test
make snapshot

# Deploy to mainnet (be careful!)
make deploy-mainnet
```

## 🆘 Troubleshooting

### Common Issues

1. **"Connection refused" error**:
   - Make sure Anvil is running: `make anvil`
   - Check if the RPC URL is correct

2. **"Insufficient funds" error**:
   - Make sure your address has enough ETH
   - For testnet, get ETH from faucets

3. **"Invalid private key" error**:
   - Make sure private key starts with `0x`
   - Verify the private key is correct

4. **"Contract not found" error**:
   - Make sure contract is deployed
   - Verify the contract address is correct

### Getting Help

- Run `make help` to see all available commands
- Check the `.env.example` file for environment setup
- Review test output for detailed error messages

## 📚 Additional Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Ethereum Testnet Faucets](https://faucetlink.to/sepolia)
- [Alchemy RPC](https://alchemy.com/)
- [Etherscan Contract Verification](https://etherscan.io/verifyContract)
