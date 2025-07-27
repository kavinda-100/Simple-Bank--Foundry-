# 🏦 Simple Bank - Foundry Makefile
# Comprehensive commands for testing, deployment, and contract interaction

# ================================
# 🧪 TESTING COMMANDS
# ================================

# Run all tests
test:
	forge test

# Run tests with verbose output
test-v:
	forge test -v

# Run tests with very verbose output (show traces)
test-vv:
	forge test -vv

# Run tests with maximum verbosity
test-vvv:
	forge test -vvv

# Run all tests with summary
test-summary:
	forge test --summary

# Run specific test categories
test-unit:
	forge test --match-path "test/unit/*" -v

test-fuzz:
	forge test --match-path "test/fuzz/*" -v

test-invariant:
	forge test --match-path "test/invariant/*" -v

test-integration:
	forge test --match-path "test/integration/*" -v

# Run specific test files
test-bank:
	forge test --match-path "test/unit/BankTest.t.sol" -v

test-account:
	forge test --match-path "test/unit/BankAccountTest.t.sol" -v

test-borrow:
	forge test --match-path "test/unit/BorrowAndPayTest.t.sol" -v

# Run tests with gas reporting
test-gas:
	forge test --gas-report

# Generate coverage report
coverage:
	forge coverage

# Generate detailed coverage report (lcov format)
coverage-report:
	forge coverage --report lcov

# ================================
# 🏗️ BUILD COMMANDS
# ================================

# Build the project
build:
	forge build

# Clean build artifacts
clean:
	forge clean

# Install dependencies
install:
	forge install

# Update dependencies
update:
	forge update

# ================================
# 🚀 PERSIST STATE COMMANDS
# ================================

# Start Anvil with state dumping (saves state when stopped)
# This command starts a fresh Anvil instance that will save its state to state.json when stopped
persist-state-dump:
	@echo "🔄 Starting Anvil with state persistence..."
	@echo "💾 State will be saved to state.json when you stop Anvil (Ctrl+C)"
	anvil --dump-state state.json

# Start Anvil and load previous state (if exists)
# This command loads a previously saved state from state.json
persist-state-load:
	@if [ -f "state.json" ]; then \
		echo "📂 Loading previous state from state.json..."; \
		anvil --load-state state.json --dump-state state.json; \
	else \
		echo "📝 No previous state found (state.json), starting fresh with state persistence..."; \
		anvil --dump-state state.json; \
	fi

# Clean state file
persist-state-clean:
	@if [ -f "state.json" ]; then \
		echo "🧹 Removing state.json..."; \
		rm state.json; \
		echo "✅ State file cleaned"; \
	else \
		echo "📝 No state file found to clean"; \
	fi

# Show state file info
persist-state-info:
	@if [ -f "state.json" ]; then \
		echo "📄 State file information:"; \
		ls -lh state.json; \
		echo "📊 File size: $$(du -h state.json | cut -f1)"; \
	else \
		echo "📝 No state file found"; \
	fi

# ================================
# 🚀 DEPLOYMENT COMMANDS
# ================================

# Deploy to local Anvil (requires anvil to be running)
deploy-local:
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url $(LOCAL_RPC_URL) \
		--private-key $(LOCAL_PRIVATE_KEY) \
		--broadcast

# Deploy to local Anvil with verification
deploy-local-verify:
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url $(LOCAL_RPC_URL) \
		--private-key $(LOCAL_PRIVATE_KEY) \
		--broadcast \
		--verify

# Deploy to Sepolia testnet (requires SEPOLIA_RPC_URL and PRIVATE_KEY env vars)
deploy-sepolia:
	@if [ -z "$(SEPOLIA_RPC_URL)" ] || [ -z "$(PRIVATE_KEY)" ]; then \
		echo "❌ Error: SEPOLIA_RPC_URL and PRIVATE_KEY environment variables must be set"; \
		echo "📝 Example: export SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"; \
		echo "📝 Example: export PRIVATE_KEY=0x..."; \
		exit 1; \
	fi
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify

# Deploy to mainnet (requires MAINNET_RPC_URL and PRIVATE_KEY env vars)
deploy-mainnet:
	@echo "⚠️  WARNING: You are about to deploy to MAINNET!"
	@echo "💰 This will cost real ETH. Make sure you understand the implications."
	@read -p "Are you sure you want to continue? (yes/no): " confirm && [ "$$confirm" = "yes" ]
	@if [ -z "$(MAINNET_RPC_URL)" ] || [ -z "$(PRIVATE_KEY)" ]; then \
		echo "❌ Error: MAINNET_RPC_URL and PRIVATE_KEY environment variables must be set"; \
		exit 1; \
	fi
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url $(MAINNET_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify

# ================================
# 🔧 UTILITY COMMANDS
# ================================

# Start local Anvil node
anvil:
	anvil

# Format code
format:
	forge fmt

# Check code formatting
format-check:
	forge fmt --check

# Run linter
lint:
	forge fmt --check

# Get contract size
size:
	forge build --sizes

# Generate documentation
docs:
	forge doc

# ================================
# 🔍 INTERACTION COMMANDS
# ================================

# Check balance of an address (requires ADDRESS env var)
# Usage: make balance ADDRESS=0x1234567890123456789012345678901234567890
balance:
	@if [ -z "$(ADDRESS)" ]; then \
		echo "❌ Error: ADDRESS environment variable must be set"; \
		echo "📝 Example: make balance ADDRESS=0x1234..."; \
		exit 1; \
	fi
	cast balance $(ADDRESS) --rpc-url http://localhost:8545

# Send ETH to an address (requires TO, AMOUNT, and optionally PRIVATE_KEY)
# Usage: make send-eth TO=0x1234... AMOUNT=1ether PRIVATE_KEY=0x...
send-eth:
	@if [ -z "$(TO)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "❌ Error: TO and AMOUNT environment variables must be set"; \
		echo "📝 Example: make send-eth TO=0x1234... AMOUNT=1ether PRIVATE_KEY=0x..."; \
		exit 1; \
	fi
	cast send $(TO) --value $(AMOUNT) --private-key $(PRIVATE_KEY) --rpc-url http://localhost:8545

# Call a contract function (requires CONTRACT, FUNCTION, and optionally ARGS)
# Usage: make call CONTRACT=0x1234... FUNCTION="getBalance(address)" ARGS=0x5678...
call:
	@if [ -z "$(CONTRACT)" ] || [ -z "$(FUNCTION)" ]; then \
		echo "❌ Error: CONTRACT and FUNCTION environment variables must be set"; \
		echo "📝 Example: make call CONTRACT=0x1234... FUNCTION=\"getBalance(address)\" ARGS=0x5678..."; \
		exit 1; \
	fi
	cast call $(CONTRACT) $(FUNCTION) $(ARGS) --rpc-url http://localhost:8545

# Send a transaction to a contract (requires CONTRACT, FUNCTION, and optionally ARGS, PRIVATE_KEY)
# Usage: make send CONTRACT=0x1234... FUNCTION="deposit()" PRIVATE_KEY=0x... ARGS="" VALUE=1ether
send:
	@if [ -z "$(CONTRACT)" ] || [ -z "$(FUNCTION)" ]; then \
		echo "❌ Error: CONTRACT and FUNCTION environment variables must be set"; \
		echo "📝 Example: make send CONTRACT=0x1234... FUNCTION=\"deposit()\" PRIVATE_KEY=0x..."; \
		exit 1; \
	fi
	cast send $(CONTRACT) $(FUNCTION) $(ARGS) --private-key $(PRIVATE_KEY) --rpc-url http://localhost:8545 $(if $(VALUE),--value $(VALUE))

# ================================
# 🏦 BANK-SPECIFIC INTERACTION COMMANDS
# ================================

# Create a bank account (requires BANK_CONTRACT, PRIVATE_KEY, DEPOSIT_AMOUNT)
# Usage: make bank-create-account BANK_CONTRACT=0x... PRIVATE_KEY=0x... DEPOSIT_AMOUNT=2ether
bank-create-account:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(PRIVATE_KEY)" ] || [ -z "$(DEPOSIT_AMOUNT)" ]; then \
		echo "❌ Error: BANK_CONTRACT, PRIVATE_KEY, and DEPOSIT_AMOUNT must be set"; \
		echo "📝 Example: make bank-create-account BANK_CONTRACT=0x... PRIVATE_KEY=0x... DEPOSIT_AMOUNT=2ether"; \
		exit 1; \
	fi
	cast send $(BANK_CONTRACT) "createAccount()" --private-key $(PRIVATE_KEY) --value $(DEPOSIT_AMOUNT) --rpc-url http://localhost:8545

# Check bank balance (requires BANK_CONTRACT, USER_ADDRESS)
# Usage: make bank-balance BANK_CONTRACT=0x... USER_ADDRESS=0x...
bank-balance:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(USER_ADDRESS)" ]; then \
		echo "❌ Error: BANK_CONTRACT and USER_ADDRESS must be set"; \
		echo "📝 Example: make bank-balance BANK_CONTRACT=0x... USER_ADDRESS=0x..."; \
		exit 1; \
	fi
	cast call $(BANK_CONTRACT) "getBalance(address)" $(USER_ADDRESS) --rpc-url http://localhost:8545

# Deposit to bank (requires BANK_CONTRACT, PRIVATE_KEY, AMOUNT)
# Usage: make bank-deposit BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1ether
bank-deposit:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(PRIVATE_KEY)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "❌ Error: BANK_CONTRACT, PRIVATE_KEY, and AMOUNT must be set"; \
		echo "📝 Example: make bank-deposit BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1ether"; \
		exit 1; \
	fi
	cast send $(BANK_CONTRACT) "receive()" --private-key $(PRIVATE_KEY) --value $(AMOUNT) --rpc-url http://localhost:8545

# Withdraw from bank (requires BANK_CONTRACT, PRIVATE_KEY, AMOUNT)
# Usage: make bank-withdraw BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1000000000000000000
bank-withdraw:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(PRIVATE_KEY)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "❌ Error: BANK_CONTRACT, PRIVATE_KEY, and AMOUNT must be set"; \
		echo "📝 Example: make bank-withdraw BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1000000000000000000"; \
		exit 1; \
	fi
	cast send $(BANK_CONTRACT) "withdraw(uint256)" $(AMOUNT) --private-key $(PRIVATE_KEY) --rpc-url http://localhost:8545

# Transfer between bank accounts (requires BANK_CONTRACT, PRIVATE_KEY, TO_ADDRESS, AMOUNT)
# Usage: make bank-transfer BANK_CONTRACT=0x... PRIVATE_KEY=0x... TO_ADDRESS=0x... AMOUNT=1000000000000000000
bank-transfer:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(PRIVATE_KEY)" ] || [ -z "$(TO_ADDRESS)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "❌ Error: BANK_CONTRACT, PRIVATE_KEY, TO_ADDRESS, and AMOUNT must be set"; \
		echo "📝 Example: make bank-transfer BANK_CONTRACT=0x... PRIVATE_KEY=0x... TO_ADDRESS=0x... AMOUNT=1000000000000000000"; \
		exit 1; \
	fi
	cast send $(BANK_CONTRACT) "transferFunds(address,uint256)" $(TO_ADDRESS) $(AMOUNT) --private-key $(PRIVATE_KEY) --rpc-url http://localhost:8545

# Borrow from bank (requires BANK_CONTRACT, PRIVATE_KEY, AMOUNT)
# Usage: make bank-borrow BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1000000000000000000
bank-borrow:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(PRIVATE_KEY)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "❌ Error: BANK_CONTRACT, PRIVATE_KEY, and AMOUNT must be set"; \
		echo "📝 Example: make bank-borrow BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1000000000000000000"; \
		exit 1; \
	fi
	cast send $(BANK_CONTRACT) "borrow(uint256)" $(AMOUNT) --private-key $(PRIVATE_KEY) --rpc-url http://localhost:8545

# Pay back loan (requires BANK_CONTRACT, PRIVATE_KEY, AMOUNT)
# Usage: make bank-payback BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1000000000000000000
bank-payback:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(PRIVATE_KEY)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "❌ Error: BANK_CONTRACT, PRIVATE_KEY, and AMOUNT must be set"; \
		echo "📝 Example: make bank-payback BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1000000000000000000"; \
		exit 1; \
	fi
	cast send $(BANK_CONTRACT) "payBackLoan()" --private-key $(PRIVATE_KEY) --value $(AMOUNT) --rpc-url http://localhost:8545

# Get borrower details (requires BANK_CONTRACT, USER_ADDRESS)
# Usage: make bank-borrower-details BANK_CONTRACT=0x... USER_ADDRESS=0x...
bank-borrower-details:
	@if [ -z "$(BANK_CONTRACT)" ] || [ -z "$(USER_ADDRESS)" ]; then \
		echo "❌ Error: BANK_CONTRACT and USER_ADDRESS must be set"; \
		echo "📝 Example: make bank-borrower-details BANK_CONTRACT=0x... USER_ADDRESS=0x..."; \
		exit 1; \
	fi
	cast call $(BANK_CONTRACT) "getBorrowerDetails(address)" $(USER_ADDRESS) --rpc-url http://localhost:8545

# ================================
# 📊 ANALYSIS COMMANDS
# ================================

# Generate gas snapshot
snapshot:
	forge snapshot

# Generate gas snapshot with comparison
snapshot-diff:
	forge snapshot --diff

# Analyze contract storage layout
storage:
	forge inspect src/Bank.sol:Bank storage-layout
	forge inspect src/BankAccount.sol:BankAccount storage-layout

# Get contract ABI
abi-bank:
	forge inspect src/Bank.sol:Bank abi

abi-account:
	forge inspect src/BankAccount.sol:BankAccount abi

# ================================
# 🆘 HELP COMMANDS
# ================================

# Show all available commands
help:
	@echo "🏦 Simple Bank - Foundry Makefile Commands"
	@echo ""
	@echo "🧪 TESTING:"
	@echo "  test              - Run all tests"
	@echo "  test-v            - Run tests with verbose output"
	@echo "  test-unit         - Run unit tests only"
	@echo "  test-fuzz         - Run fuzz tests only"
	@echo "  test-invariant    - Run invariant tests only"
	@echo "  test-integration  - Run integration tests only"
	@echo "  test-gas          - Run tests with gas reporting"
	@echo "  coverage          - Generate coverage report"
	@echo ""
	@echo "🏗️ BUILD:"
	@echo "  build             - Build the project"
	@echo "  clean             - Clean build artifacts"
	@echo "  install           - Install dependencies"
	@echo ""
	@echo "🚀 DEPLOYMENT:"
	@echo "  deploy-local      - Deploy to local Anvil"
	@echo "  deploy-sepolia    - Deploy to Sepolia testnet"
	@echo "  deploy-goerli     - Deploy to Goerli testnet"
	@echo "  simulate-deploy   - Simulate deployment"
	@echo ""
	@echo "🔧 UTILITIES:"
	@echo "  anvil             - Start local Anvil node"
	@echo "  persist-state-dump - Start Anvil with state dumping"
	@echo "  persist-state-load - Start Anvil with state loading"
	@echo "  persist-state-clean - Clean state file"
	@echo "  persist-state-info - Show state file info"
	@echo "  format            - Format code"
	@echo "  size              - Check contract sizes"
	@echo ""
	@echo "🔍 INTERACTION:"
	@echo "  balance           - Check address balance"
	@echo "  call              - Call contract function"
	@echo "  send              - Send transaction"
	@echo ""
	@echo "🏦 BANK OPERATIONS:"
	@echo "  bank-create-account  - Create bank account"
	@echo "  bank-balance         - Check bank balance"
	@echo "  bank-deposit         - Deposit to bank"
	@echo "  bank-withdraw        - Withdraw from bank"
	@echo "  bank-transfer        - Transfer between accounts"
	@echo "  bank-borrow          - Borrow from bank"
	@echo "  bank-payback         - Pay back loan"
	@echo ""
	@echo "📊 ANALYSIS:"
	@echo "  snapshot          - Generate gas snapshot"
	@echo "  storage           - Show storage layout"
	@echo "  abi-bank          - Get Bank contract ABI"
	@echo ""
	@echo "💡 USAGE EXAMPLES:"
	@echo "  make balance ADDRESS=0x1234..."
	@echo "  make bank-balance BANK_CONTRACT=0x... USER_ADDRESS=0x..."
	@echo "  make bank-deposit BANK_CONTRACT=0x... PRIVATE_KEY=0x... AMOUNT=1ether"

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: test test-v test-vv test-vvv test-summary test-unit test-fuzz test-invariant test-integration \
        test-bank test-account test-borrow test-gas coverage coverage-report build clean install update \
        deploy-local deploy-local-verify deploy-sepolia deploy-goerli deploy-mainnet simulate-deploy \
        anvil anvil-custom format format-check lint size docs balance send-eth call send \
        persist-state-dump persist-state-load persist-state-clean persist-state-info \
        bank-create-account bank-balance bank-deposit bank-withdraw bank-transfer bank-borrow bank-payback bank-borrower-details \
        snapshot snapshot-diff storage abi-bank abi-account help