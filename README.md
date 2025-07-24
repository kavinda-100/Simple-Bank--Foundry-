# 🏦 Simple Bank - Foundry

A comprehensive decentralized banking application built with Solidity and Foundry Framework. This project demonstrates advanced smart contract development with proper access controls, testing, and deployment automation.Total: **118 tests passed** ✅

## ✨ Features

- [x] Create a new bank account with minimum balance requirement
- [x] Deposit funds into an account
- [x] Withdraw funds from an account
- [x] Check account balance
- [x] Transfer funds between accounts
- [x] Borrow funds with interest calculation
- [x] Pay back borrowed funds with interest
- [x] Account activation/freezing system
- [x] Role-based access control
- [x] Comprehensive event logging

## 🏗️ Architecture

The system consists of two main contracts:

### 📋 BankAccount.sol

- Handles core banking operations (deposits, withdrawals, transfers)
- Manages user account balances and creation
- Implements access control for admin functions
- Processes loan payments and receipts

### 🏛️ Bank.sol

- Manages the borrowing and lending system
- Handles account activation/freezing
- Calculates interest on borrowed funds
- Integrates with BankAccount for loan operations
  
## 🔧 Key Features in Detail

### 💰 Borrowing System

- Interest rate calculation (5% annual rate)
- Maximum borrowing limits (100 ETH)
- 30-day loan terms
- Automatic due date tracking

### 🔐 Access Control

- Role-based permissions using OpenZeppelin AccessControl
- Admin functions for loan management
- Account freezing/activation capabilities

### 🛡️ Security Features

- Input validation on all functions
- Reentrancy protection
- Proper error handling with custom errors
- Comprehensive event logging
- **99.15% test coverage** for Bank.sol with comprehensive edge case testing
- **100% test coverage** for BankAccount.sol ensuring all edge cases are tested

## 🛠️ Tools & Technologies

- **Foundry Framework** - Development, testing, and deployment
- **Solidity ^0.8.24** - Smart contract language
- **OpenZeppelin Contracts** - Access control and security
- **Forge** - Testing framework
- **Cast** - Blockchain interaction tool

## 📁 Project Structure

```md
├── src/
│   ├── Bank.sol                    # Main banking contract with borrowing functionality
│   ├── BankAccount.sol             # Core account management contract
│   └── interfaces/
│       └── IBankAccount.sol        # Interface for BankAccount contract
├── test/
│   ├── unit/                        # Unit tests for individual contract functions
│   │   ├── AccessControlTest.t.sol  # Tests for role-based access control
│   │   ├── AccountActivation.t.sol  # Tests for account activation and freezing
│   │   ├── BankAccountTest.t.sol    # Tests for BankAccount contract edge cases and errors
│   │   ├── BankTest.t.sol           # Tests for Bank contract edge cases and validations
│   │   ├── BorrowAndPayTest.t.sol   # Tests for borrowing and payment functionality
│   │   └── EthHandlingTest.t.sol    # Tests for ETH deposits, withdrawals, transfers
│   ├── fuzz/                        # Fuzz tests for property-based testing
│   │   └── BankFuzzTest.t.sol       # Fuzz tests for edge cases with random inputs
│   ├── invariant/                   # Invariant tests for critical properties
│   │   └── BankInvariantTest.t.sol  # Tests that critical properties always hold
│   └── integration/                 # Integration tests for end-to-end workflows
│       └── BankIntegrationTest.t.sol # Tests for complex multi-user scenarios
├── script/
│   ├── DeployBankSystem.s.sol      # Complete system deployment (recommended)
│   └── deprecated/
│       ├── DeployBank.s.sol        # Individual Bank deployment (deprecated)
│       └── DeployBankAccount.s.sol # Individual BankAccount deployment (deprecated)
├── lib/
│   ├── forge-std/                  # Foundry standard library
│   └── openzeppelin-contracts/     # OpenZeppelin contracts
├── cache/                          # Foundry cache files
├── DEPLOYMENT.md                   # Deployment guide and instructions
├── MIGRATION_SUMMARY.md            # Summary of recent system updates
├── README.md                       # This file
└── foundry.toml                    # Foundry configuration
```

## 🚀 Quick Start

### 📋 Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 📦 Installation

```bash
# Clone the repository
git clone https://github.com/kavinda-100/Simple-Bank--Foundry-.git
cd Simple-Bank--Foundry-

# Install dependencies
forge install

# Build the project
forge build
```

### 🧪 Testing

### 📊 Code Coverage

```md
╭-------------------------+----------+-----------+-----------+---------╮
| File                    | % Lines  | % Stmts   | % Branch  | % Funcs |
+=================================================================+
| src/Bank.sol            | 99.15%   | 99.04%    | 93.75%    | 100.00% |
|-------------------------+----------+-----------+-----------+---------|
| src/BankAccount.sol     | 100.00%  | 100.00%   | 100.00%   | 100.00% |
|-------------------------+----------+-----------+-----------+---------|
| DeployBankSystem.s.sol  | 100.00%  | 100.00%   | 100.00%   | 100.00% |
╰-------------------------+----------+-----------+-----------+---------╯
```

**Both main contracts have achieved near-perfect test coverage!** 🎉

- **BankAccount.sol**: 100% coverage across all metrics
- **Bank.sol**: 99.15% lines, 99.04% statements, 93.75% branches, 100% functions

### 📈 Current Test Status

```md
╭-----------------------+--------+--------+---------╮
| Test Suite            | Passed | Failed | Skipped |
+===================================================+
| BankFuzzTest          | 5      | 0      | 0       |
|-----------------------+--------+--------+---------|
| BankIntegrationTest   | 5      | 0      | 0       |
|-----------------------+--------+--------+---------|
| BankInvariantTest     | 7      | 0      | 0       |
|-----------------------+--------+--------+---------|
| AccessControlTest     | 3      | 0      | 0       |
|-----------------------+--------+--------+---------|
| AccountActivationTest | 11     | 0      | 0       |
|-----------------------+--------+--------+---------|
| BankAccountTest       | 19     | 0      | 0       |
|-----------------------+--------+--------+---------|
| BankTest              | 19     | 0      | 0       |
|-----------------------+--------+--------+---------|
| BorrowAndPayTest      | 27     | 0      | 0       |
|-----------------------+--------+--------+---------|
| EthHandlingTest       | 22     | 0      | 0       |
╰-----------------------+--------+--------+---------╯
```

Total: **118 tests passed** ✅

### 🧪 Test Categories

#### Unit Tests (101 tests)

- **AccessControlTest (3 tests)**: Role-based permissions and owner verification
- **AccountActivationTest (11 tests)**: Account activation, freezing, and authorization testing
- **BankAccountTest (19 tests)**: Direct BankAccount contract testing including edge cases, error conditions, invalid inputs, and transfer failures
- **BankTest (19 tests)**: Comprehensive Bank contract testing including zero address validations, transfer failures, unauthorized operations, and complex edge cases
- **BorrowAndPayTest (27 tests)**: Borrowing system, interest calculation, loan management, due date handling
- **EthHandlingTest (22 tests)**: Account creation, deposits, withdrawals, transfers, validations

#### Advanced Testing (17 tests)

- **BankFuzzTest (5 tests)**: Property-based testing with random inputs to discover edge cases in deposits, borrowing, transfers, withdrawals, and interest calculations
- **BankInvariantTest (7 tests)**: Critical property validation ensuring bank solvency, balance consistency, interest bounds, and system integrity
- **BankIntegrationTest (5 tests)**: End-to-end workflow testing including complete lending cycles, concurrent borrowing, account management, and stress testing.

## 📊 Testing Coverage

The project includes comprehensive test coverage across all contracts with **multiple testing methodologies**:

- **118 total test cases** covering all functionality across 4 test categories
- **Unit tests (101 tests)** for individual contract functions
- **Fuzz tests (5 tests)** for property-based testing with random inputs
- **Invariant tests (7 tests)** for critical property validation
- **Integration tests (5 tests)** for end-to-end workflow testing
- Access control and security testing
- Event emission verification
- Edge case and error condition testing

```bash
# Run all tests
forge test

# Run tests with detailed output
forge test -vv

# Run specific test file
forge test --match-path test/unit/BorrowAndPayTest.t.sol

# Run specific test contract
forge test --match-contract BankAccountTest

# Run with gas reporting
forge test --gas-report

# Generate coverage report
forge coverage

# Generate detailed coverage report
forge coverage --report lcov
```

Additional Testing

- 🎲 **Fuzz Testing**: Adds robustness against unexpected inputs
- ⚖️ **Invariant Testing**: Ensures critical properties always hold
- 🔗 **Integration Testing**: Validates complex real-world scenarios

## 📦 Commands to Run Each Test Type

```bash
# Run all unit tests
forge test --match-path "test/unit/*" -v

# Run fuzz tests
forge test --match-path "test/fuzz/*" -v

# Run invariant tests
forge test --match-path "test/invariant/*" -v

# Run integration tests
forge test --match-path "test/integration/*" -v

# Run all tests
forge test --summary

# Generate coverage report
forge coverage
```

### 🚀 Deployment

#### 🏠 Local Deployment (Anvil)

```bash
# Start local blockchain
anvil

# Deploy complete system (in another terminal)
forge script script/DeployBankSystem.s.sol:DeployBankSystem \
  --fork-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

#### 🌐 Testnet/Mainnet Deployment

```bash
# Set environment variables
export RPC_URL="your_rpc_url"
export PRIVATE_KEY="your_private_key"

# Deploy complete system
forge script script/DeployBankSystem.s.sol:DeployBankSystem \
  --fork-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

## 📚 Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Comprehensive deployment guide
- [Foundry Book](https://book.getfoundry.sh/) - Foundry documentation

## 👨‍💻 Author

Kavinda Rathnayake

- GitHub: [@kavinda-100](https://github.com/kavinda-100)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
