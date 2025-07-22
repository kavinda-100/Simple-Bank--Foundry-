// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/Bank.sol";
import "../../src/BankAccount.sol";

// import deployment scripts
import {DeployBank} from "../../script/DeployBank.s.sol";
import {DeployBankAccount} from "../../script/DeployBankAccount.s.sol";

contract EthHandlingTest is Test {
    // Contracts to test
    Bank public bank;
    BankAccount public bankAccount;
    address public bankAccountDeployer;
    address public bankDeployer;
    
    // Addresses for test users
    address public user1 = address(0x123);
    address public user2 = address(0x456);

    // constants
    uint256 constant USER_DEPOSIT_AMOUNT = 2 ether;

    // Events ---------------------------------------------------------------------------------------------
    event Deposit(address indexed owner, uint256 amount); // Event emitted when a deposit is made
    event Withdrawal(address indexed owner, uint256 amount); // Event emitted when a withdrawal is made
    event Transfer(address indexed from, address indexed to, uint256 amount); // Event emitted when funds are transferred
    event CreateAnAccount(address indexed owner, uint256 amount); // Event emitted when an account is created
    
    function setUp() public {
        // Deploy BankAccount using deployment script
        DeployBankAccount deployBankAccountScript = new DeployBankAccount();
        (bankAccount, bankAccountDeployer) = deployBankAccountScript.run();

        // Deploy Bank using deployment script
        DeployBank deployBankScript = new DeployBank();
        (bank, bankDeployer) = deployBankScript.run(address(bankAccount));
        
        // Give test users some ETH to work with
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    // ============================== Tests for Create An Account Functionality =========================================
    /**
     * @dev Test to verify creating a new account
     */
    function test_CreateAccount() public {
        console.log("=== Create Account Test ===");
        // Start prank as user1 to create an account
        vm.startPrank(user1);

        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();
        // Check if the account was created successfully
        uint256 user1Balance = bankAccount.getBalance(user1);
        console.log("User1 account balance after creation:", user1Balance);
        assertEq(user1Balance, USER_DEPOSIT_AMOUNT, "Account creation failed or balance mismatch");
        // Check if the BankAccount contract received the ETH
        assertEq(address(bankAccount).balance, USER_DEPOSIT_AMOUNT, "BankAccount contract receive the ETH");
        console.log("BankAccount contract balance after creation:", address(bankAccount).balance);

        vm.stopPrank();
    }
    /**
     * @dev Test to verify creating an account emits CreateAnAccount event
     */
    function test_CreateAccountEventEmitted() public {
        console.log("=== Create Account Event Emitted Test ===");
        vm.startPrank(user1);

        // Check if the BankAccount contract emitted the CreateAnAccount event
        vm.expectEmit(true, false, false, true);
        emit CreateAnAccount(user1, USER_DEPOSIT_AMOUNT);

        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();

        vm.stopPrank();
    }

    /**
     * @dev Test to verify creating an account with BankAccount__DepositAmountMustBeGreaterThanMinimumAmount reverts
     */
    function test_CreateAccountWithInsufficientDepositReverts() public {
        console.log("=== Create Account With Insufficient Deposit Reverts Test ===");
        vm.startPrank(user1);

        // Try to create an account with 0 ETH
        vm.expectRevert(BankAccount.BankAccount__DepositAmountMustBeGreaterThanMinimumAmount.selector);
        bank.createAccount{value: 0}();

        vm.stopPrank();
    }

    /**
     * @dev Test to verify creating an account with BankAccount__AccountAlreadyExists reverts
     */
    function test_CreateAccountWithExistingAccountReverts() public {
        console.log("=== Create Account With Existing Account Reverts Test ===");
        vm.startPrank(user1);

        // Create the account first
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();

        // Try to create the account again
        vm.expectRevert(BankAccount.BankAccount__AccountAlreadyExists.selector);
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();

        vm.stopPrank();
    }

    // ============================== Tests for Deposit Functionality =========================================

    /**
     * @dev Test to verify ETH deposit directly to BankAccount
     */
    function test_DepositEthDirectly() public {
        console.log("=== Deposit ETH Directly to BankAccount Contract Test ===");
        vm.startPrank(user1);
        
        uint256 depositAmount = 1 ether;
        uint256 initialBalance = user1.balance;
        
        // Deposit ETH directly to BankAccount
        bankAccount.deposit{value: depositAmount}(user1);
        
        // Check user's ETH balance decreased
        assertEq(user1.balance, initialBalance - depositAmount);
        
        // Check user's account balance increased
        assertEq(bankAccount.getBalance(user1), depositAmount);
        
        // Check contract received the ETH
        assertEq(address(bankAccount).balance, depositAmount);
        
        vm.stopPrank();
    }
    
    /**
     * @dev Test to verify ETH deposit through Bank contract
     */
    function test_DepositEthThroughBank() public {
        console.log("=== Deposit ETH Through Bank Contract Test ===");

        vm.startPrank(user1);
        
        uint256 depositAmount = 2 ether;
        uint256 initialBalance = user1.balance;

        console.log("Before deposit: ===================");
        console.log("User1 initial balance:", initialBalance);
        console.log("BankAccount initial balance:", address(bankAccount).balance);
        console.log("Bank initial balance:", address(bank).balance);
        
        // Deposit ETH through Bank contract
        bank.deposit{value: depositAmount}();
        
        console.log("After deposit: ===================");
        console.log("User1 balance:", user1.balance);
        console.log("User1 account balance:", bankAccount.getBalance(user1));
        console.log("BankAccount contract balance:", address(bankAccount).balance);
        console.log("Bank contract balance:", address(bank).balance);
        
        // Check user's ETH balance decreased
        assertEq(user1.balance, initialBalance - depositAmount);
        
        // Check user's account balance increased
        assertEq(bankAccount.getBalance(user1), depositAmount);
        
        // Check BankAccount contract received the ETH
        assertEq(address(bankAccount).balance, depositAmount);
        
        vm.stopPrank();
    }

    /**
     * @dev Test to verify Deposit event is emitted when depositing ETH
     */
    function test_DepositEventEmitted() public {
        console.log("=== Deposit Event Emitted Test ===");
        
        vm.startPrank(user1);
        
        uint256 depositAmount = 1 ether;

        // Expect Deposit event to be emitted
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, depositAmount);
        
        // Deposit ETH through BankAccount
        bank.deposit{value: depositAmount}();
        
        vm.stopPrank();
    }

    /**
     * @dev Test to verify of send 0 ETH to BankAccount it should be reverted
     */
    function test_SendZeroEthReverts() public {
        console.log("=== Send 0 ETH to BankAccount Reverts Test ===");
        
        vm.startPrank(user1);
        
        // Expect revert when sending 0 ETH
        vm.expectRevert(BankAccount.BankAccount__DepositAmountMustBeGreaterThanZero.selector);

        // Attempt to deposit 0 ETH
        bank.deposit{value: 0}();
        
        vm.stopPrank();
    }

    /**
     * @dev Test to verify user address is valid when depositing ETH
     */
    function test_ValidUserAddressOnDeposit() public {
        console.log("=== Valid User Address on Deposit Test ===");
        
        vm.startPrank(user1);
        
        uint256 depositAmount = 1 ether;
        
        // Expect revert if user address is zero
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        
        // Attempt to deposit with zero address
        bankAccount.deposit{value: depositAmount}(address(0));
        
        vm.stopPrank();
    }

    // ============================== Tests for Withdraw Functionality =========================================

    /**
     * @dev Test to verify ETH withdrawal from BankAccount
     */
    function test_WithdrawEthFromBankAccount() public {
        console.log("=== Withdraw ETH from BankAccount Test ===");
        vm.startPrank(user1);
        uint256 depositAmount = 2 ether;
        uint256 withdrawAmount = 1 ether;

        // Deposit ETH to withdraw later
        bank.deposit{value: depositAmount}();

        // Check initial balances
        console.log("Before withdrawal: ===================");
        console.log("User1 balance:", user1.balance);
        console.log("User1 account balance:", bankAccount.getBalance(user1));
        console.log("BankAccount contract balance:", address(bankAccount).balance);
        console.log("Bank contract balance:", address(bank).balance);

        // Withdraw ETH from BankAccount
        bank.withdraw(withdrawAmount);

        // Check final balances
        console.log("After withdrawal: ===================");
        console.log("User1 balance:", user1.balance);
        console.log("User1 account balance:", bankAccount.getBalance(user1));
        console.log("BankAccount contract balance:", address(bankAccount).balance);
        console.log("Bank contract balance:", address(bank).balance);

        // Check user's account balance decreased
        assertEq(bankAccount.getBalance(user1), depositAmount - withdrawAmount);

        // Check BankAccount contract balance decreased
        assertEq(address(bankAccount).balance, depositAmount - withdrawAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test to verify withdrawal reverts if insufficient balance
     */
    function test_WithdrawInsufficientBalanceReverts() public {
        console.log("=== Withdraw Insufficient Balance Reverts Test ===");
        
        vm.startPrank(user1);
        
        // Expect revert if trying to withdraw more than balance (this user has no balance yet)
        vm.expectRevert(BankAccount.BankAccount__InsufficientBalance.selector);
        
        // Attempt to withdraw more than deposited amount
        bank.withdraw(1 ether);
        
        vm.stopPrank();
    }

    /**
     * @dev Test to verify Withdrawal event is emitted when withdrawing ETH
     */
    function test_WithdrawalEventEmitted() public {
        console.log("=== Withdrawal Event Emitted Test ===");
        
        vm.startPrank(user1);
        
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.5 ether;

        // Deposit ETH to withdraw later
        bank.deposit{value: depositAmount}();

        // Expect Withdrawal event to be emitted
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(user1, withdrawAmount);
        
        // Withdraw ETH from BankAccount
        bank.withdraw(withdrawAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test to verify user address is valid when withdrawing ETH
     */
    function test_ValidUserAddressOnWithdraw() public {
        console.log("=== Valid User Address on Withdraw Test ===");

        vm.startPrank(user1);
        
        uint256 depositAmount = 1 ether;
        
        // Expect revert if user address is zero
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);

        // Attempt to withdraw with zero address
        bankAccount.withdraw(address(0), depositAmount);
        
        vm.stopPrank();
    }

    // ============================== Tests for Transfer funds Functionality =========================================

    /**
     * @dev Test to verify transferring funds between accounts
     */
    function test_TransferFundsBetweenAccounts() public {
        console.log("=== Transfer Funds Between Accounts Test ===");
        
        vm.startPrank(user1);
        
        uint256 depositAmount = 2 ether;
        uint256 transferAmount = 1 ether;

        // Deposit ETH to transfer later
        bankAccount.deposit{value: depositAmount}(user1);

        // Check initial balances
        console.log("Before transfer: ===================");
        console.log("User1 balance:", user1.balance);
        console.log("User2 balance:", user2.balance);
        console.log("User1 account balance:", bankAccount.getBalance(user1));
        console.log("User2 account balance:", bankAccount.getBalance(user2));

        // Transfer funds from user1 to user2
        bank.transferFunds(user2, transferAmount);

        // Check final balances
        console.log("After transfer: ===================");
        console.log("User1 balance:", user1.balance);
        console.log("User2 balance:", user2.balance);
        console.log("User1 account balance:", bankAccount.getBalance(user1));
        console.log("User2 account balance:", bankAccount.getBalance(user2));

        // Check user's account balances
        assertEq(bankAccount.getBalance(user1), depositAmount - transferAmount);
        assertEq(bankAccount.getBalance(user2), transferAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test to verify transfer reverts if insufficient balance
     */
    function test_TransferInsufficientBalanceReverts() public {
        console.log("=== Transfer Insufficient Balance Reverts Test ===");
        
        vm.startPrank(user1);
        
        // Expect revert if trying to transfer more than balance (this user has no balance yet)
        vm.expectRevert(BankAccount.BankAccount__InsufficientBalance.selector);
        
        // Attempt to transfer more than deposited amount
        bank.transferFunds(user2, 1 ether);
        
        vm.stopPrank();
    }

    /**
     * @dev Test to verify Transfer event is emitted when transferring funds
     */
    function test_TransferEventEmitted() public {
        console.log("=== Transfer Event Emitted Test ===");

        vm.startPrank(user1);

        uint256 depositAmount = 2 ether;
        uint256 transferAmount = 1 ether;

        // Deposit ETH to transfer later
        bank.deposit{value: depositAmount}();

        // Expect Transfer event to be emitted
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, transferAmount);

        // Attempt to transfer funds
        bankAccount.transferFunds(user1, user2, transferAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test to verify user address is valid when transferring ETH
     */
    function test_ValidUserAddressOnTransfer() public {
        console.log("=== Valid User Address on Transfer Test ===");

        vm.startPrank(user1);

        uint256 transferAmount = 1 ether;

        // Expect revert if user address is zero
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);

        // Attempt to transfer with zero address
        bankAccount.transferFunds(address(0), user2, transferAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test to verify user address is valid when transferring ETH
     */
    function test_ValidUserAddressOnTransferBySecondUser() public {
        console.log("=== Valid User Address on Transfer Test ===");

        vm.startPrank(user1);

        uint256 transferAmount = 1 ether;

        // Expect revert if user address is zero
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);

        // Attempt to transfer with zero address
        bankAccount.transferFunds(user1, address(0), transferAmount);

        vm.stopPrank();
    }

    // ============================== Tests for view functions =========================================
    /**
     * @dev Test to verify getBalance returns correct balance for user
     */
    function test_GetBalance() public {
        console.log("=== Get Balance Test ===");

        vm.startPrank(user1);

        uint256 depositAmount = 2 ether;

        // Deposit ETH to get balance
        bank.deposit{value: depositAmount}();

        // Check balance
        uint256 balance = bankAccount.getBalance(user1);
        console.log("User1 balance:", balance);

        assertEq(balance, depositAmount, "GetBalance return expected amount");

        vm.stopPrank();
    }

    /**
     * @dev Test to verify getBalance reverts for invalid user address
     */
    function test_GetBalanceInvalidAddress() public {
        console.log("=== Get Balance Invalid Address Test ===");

        vm.startPrank(user1);

        // Expect revert if user address is zero
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);

        // Attempt to get balance for zero address
        bankAccount.getBalance(address(0));

        vm.stopPrank();

    }

    /**
     * @dev Test to verify getBalance returns zero for user with no balance
     */
    function test_GetBalanceNoBalance() public {
        console.log("=== Get Balance No Balance Test ===");

        vm.startPrank(user1);

        // Check balance for user with no balance
        uint256 balance = bankAccount.getBalance(user1);
        console.log("User1 balance:", balance);

        assertEq(balance, 0, "GetBalance return zero for user with no balance");

        vm.stopPrank();
    }

}
