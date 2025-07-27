# 🔧 Makefile Arguments Guide

This guide shows you all the different ways to pass arguments to your Makefile commands.

## 📝 Methods to Pass Arguments

### 1. Environment Variables (Recommended)

The most common and flexible way to pass arguments:

```bash
# Single argument
make balance ADDRESS=0x1234567890123456789012345678901234567890

# Multiple arguments
make bank-deposit BANK_CONTRACT=0xYourBankContract PRIVATE_KEY=0xYourPrivateKey AMOUNT=1ether
```

### 2. Export Environment Variables First

```bash
# Export variables first
export BANK_CONTRACT=0x1234567890123456789012345678901234567890
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export AMOUNT=1ether

# Then use them in commands
make bank-deposit
make bank-withdraw AMOUNT=0.5ether  # Override specific variable
```

### 3. Using .env File

```bash
# Create .env file (copy from .env.example)
cp .env.example .env

# Edit .env with your values
nano .env

# Source the environment
source .env

# Now you can use commands without specifying variables each time
make bank-balance USER_ADDRESS=0x1234...
```

## 🏦 Bank-Specific Command Examples

Here are practical examples for each bank operation:

### 🏗️ Setup (Deploy First)

```bash
# Start local blockchain
make anvil

# Deploy contracts (in another terminal)
make deploy-local

# Note the deployed contract addresses from the output
# Example output: Bank deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

### 👤 Account Management

```bash
# Create a bank account with 2 ETH deposit
make bank-create-account \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  DEPOSIT_AMOUNT=2ether

# Check your bank balance
make bank-balance \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### 💰 Deposit & Withdraw

```bash
# Deposit 1 ETH to your bank account
make bank-deposit \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  AMOUNT=1ether

# Withdraw 0.5 ETH (amount in wei: 500000000000000000)
make bank-withdraw \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  AMOUNT=500000000000000000
```

### 🔄 Transfer Between Accounts

```bash
# Transfer 0.1 ETH to another account
make bank-transfer \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  TO_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  AMOUNT=100000000000000000
```

### 🏦 Borrowing & Lending

```bash
# Borrow 1 ETH
make bank-borrow \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  AMOUNT=1000000000000000000

# Check borrower details
make bank-borrower-details \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Pay back loan (amount + interest)
make bank-payback \
  BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  AMOUNT=1050000000000000000
```

## 🛠️ Generic Contract Interaction

### 📞 Calling Functions (Read-Only)

```bash
# Call any contract function
make call \
  CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  FUNCTION="getBalance(address)" \
  ARGS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Call function with multiple arguments
make call \
  CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  FUNCTION="someFunction(address,uint256)" \
  ARGS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 1000000000000000000"
```

### ✍️ Sending Transactions

```bash
# Send transaction without ETH value
make send \
  CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  FUNCTION="withdraw(uint256)" \
  ARGS=1000000000000000000 \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Send transaction with ETH value
make send \
  CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  FUNCTION="deposit()" \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  VALUE=1ether
```

## 🌐 Working with Different Networks

### 🏠 Local Development (Anvil)

```bash
# All commands use localhost:8545 by default
make bank-balance BANK_CONTRACT=0x... USER_ADDRESS=0x...
```

### 🧪 Testnet (Sepolia)

Modify the RPC URL in commands or add network-specific versions:

```bash
# You can modify the makefile or override in commands
# For now, edit the --rpc-url in the makefile for testnet usage
```

## 💡 Pro Tips

### 1. **Use Script Files for Complex Operations**

Create a bash script for complex sequences:

```bash
# create_account_and_deposit.sh
#!/bin/bash
BANK_CONTRACT="0x5FbDB2315678afecb367f032d93F642f64180aa3"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

echo "Creating account..."
make bank-create-account BANK_CONTRACT=$BANK_CONTRACT PRIVATE_KEY=$PRIVATE_KEY DEPOSIT_AMOUNT=2ether

echo "Checking balance..."
make bank-balance BANK_CONTRACT=$BANK_CONTRACT USER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### 2. **Using Variables for Repeated Values**

```bash
# Set common variables
export BANK_CONTRACT=0x5FbDB2315678afecb367f032d93F642f64180aa3
export MY_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export MY_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Now use shorter commands
make bank-balance USER_ADDRESS=$MY_ADDRESS
make bank-deposit PRIVATE_KEY=$MY_PRIVATE_KEY AMOUNT=1ether
```

### 3. **Amount Conversion**

```bash
# ETH amounts (use ether suffix)
AMOUNT=1ether        # 1 ETH
AMOUNT=0.5ether      # 0.5 ETH
AMOUNT=2.5ether      # 2.5 ETH

# Wei amounts (exact numbers)
AMOUNT=1000000000000000000      # 1 ETH in wei
AMOUNT=500000000000000000       # 0.5 ETH in wei
```

### 4. **Checking Command Results**

```bash
# Most commands return transaction hashes or values
# Example output:
# 0x1234567890abcdef...  (transaction hash)
# 1000000000000000000    (balance in wei)
```

## 🔍 Debugging Arguments

If a command fails, check:

1. **Variable Names**: Make sure they match exactly
2. **Address Format**: Must start with `0x` and be 42 characters
3. **Amount Format**: Use `ether` suffix or exact wei amounts
4. **Private Key**: Must start with `0x` and be 66 characters

Example error checking:

```bash
# Check if variable is set
echo $BANK_CONTRACT

# Verify address format
echo "Length: ${#BANK_CONTRACT}"  # Should be 42

# Test with a simple command first
make balance ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

## 📚 Quick Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `ADDRESS` | Any Ethereum address | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| `BANK_CONTRACT` | Deployed Bank contract address | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| `PRIVATE_KEY` | Account private key | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` |
| `AMOUNT` | ETH amount | `1ether` or `1000000000000000000` |
| `USER_ADDRESS` | User's address to check | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` |
| `TO_ADDRESS` | Recipient address | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` |

Happy coding! 🚀
