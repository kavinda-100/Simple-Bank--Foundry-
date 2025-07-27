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
# 🚀 DEPLOYMENT COMMANDS
# ================================

# Deploy to local Anvil (requires anvil to be running)
deploy-local:
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url http://localhost:8545 \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast

# Deploy to local Anvil with verification
deploy-local-verify:
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url http://localhost:8545 \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
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

# Deploy to Goerli testnet (requires GOERLI_RPC_URL and PRIVATE_KEY env vars)
deploy-goerli:
	@if [ -z "$(GOERLI_RPC_URL)" ] || [ -z "$(PRIVATE_KEY)" ]; then \
		echo "❌ Error: GOERLI_RPC_URL and PRIVATE_KEY environment variables must be set"; \
		echo "📝 Example: export GOERLI_RPC_URL=https://eth-goerli.g.alchemy.com/v2/YOUR_KEY"; \
		echo "📝 Example: export PRIVATE_KEY=0x..."; \
		exit 1; \
	fi
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url $(GOERLI_RPC_URL) \
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

# Simulate deployment without broadcasting
simulate-deploy:
	forge script script/DeployBankSystem.s.sol:DeployBankSystem \
		--fork-url http://localhost:8545

# ================================
# 🔧 UTILITY COMMANDS
# ================================

# Start local Anvil node
anvil:
	anvil

# Start Anvil with custom settings
anvil-custom:
	anvil --accounts 10 --balance 1000 --gas-limit 12000000

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
balance:
	@if [ -z "$(ADDRESS)" ]; then \
		echo "❌ Error: ADDRESS environment variable must be set"; \
		echo "📝 Example: make balance ADDRESS=0x1234..."; \
		exit 1; \
	fi
	cast balance $(ADDRESS) --rpc-url http://localhost:8545

# Send ETH to an address (requires TO, AMOUNT, and optionally PRIVATE_KEY)
send-eth:
	@if [ -z "$(TO)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "❌ Error: TO and AMOUNT environment variables must be set"; \
		echo "📝 Example: make send-eth TO=0x1234... AMOUNT=1ether"; \
		exit 1; \
	fi
	cast send $(TO) --value $(AMOUNT) --private-key $(PRIVATE_KEY) --rpc-url http://localhost:8545

# Call a contract function (requires CONTRACT, FUNCTION, and optionally ARGS)
call:
	@if [ -z "$(CONTRACT)" ] || [ -z "$(FUNCTION)" ]; then \
		echo "❌ Error: CONTRACT and FUNCTION environment variables must be set"; \
		echo "📝 Example: make call CONTRACT=0x1234... FUNCTION=\"getBalance(address)\" ARGS=0x5678..."; \
		exit 1; \
	fi
	cast call $(CONTRACT) $(FUNCTION) $(ARGS) --rpc-url http://localhost:8545

# Send a transaction to a contract (requires CONTRACT, FUNCTION, and optionally ARGS, PRIVATE_KEY)
send:
	@if [ -z "$(CONTRACT)" ] || [ -z "$(FUNCTION)" ]; then \
		echo "❌ Error: CONTRACT and FUNCTION environment variables must be set"; \
		echo "📝 Example: make send CONTRACT=0x1234... FUNCTION=\"deposit()\" PRIVATE_KEY=0x..."; \
		exit 1; \
	fi
	cast send $(CONTRACT) $(FUNCTION) $(ARGS) --private-key $(PRIVATE_KEY) --rpc-url http://localhost:8545

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
	@echo "  format            - Format code"
	@echo "  size              - Check contract sizes"
	@echo ""
	@echo "🔍 INTERACTION:"
	@echo "  balance           - Check address balance"
	@echo "  call              - Call contract function"
	@echo "  send              - Send transaction"
	@echo ""
	@echo "📊 ANALYSIS:"
	@echo "  snapshot          - Generate gas snapshot"
	@echo "  storage           - Show storage layout"
	@echo "  abi-bank          - Get Bank contract ABI"

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: test test-v test-vv test-vvv test-summary test-unit test-fuzz test-invariant test-integration \
        test-bank test-account test-borrow test-gas coverage coverage-report build clean install update \
        deploy-local deploy-local-verify deploy-sepolia deploy-goerli deploy-mainnet simulate-deploy \
        anvil anvil-custom format format-check lint size docs balance send-eth call send \
        snapshot snapshot-diff storage abi-bank abi-account help