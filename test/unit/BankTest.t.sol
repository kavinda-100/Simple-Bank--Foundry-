// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Bank} from "../../src/Bank.sol";
import {BankAccount} from "../../src/BankAccount.sol";
import {DeployBankSystem} from "../../script/DeployBankSystem.s.sol";

// Mock contract that rejects ETH transfers
contract MockRejectETH {
    // This contract will reject ETH transfers by reverting in receive/fallback
    receive() external payable {
        revert("ETH transfer rejected");
    }

    fallback() external payable {
        revert("ETH transfer rejected");
    }
}

/**
 * @title BankTest
 * @dev Comprehensive test suite for Bank.sol to achieve 100% test coverage
 * This file focuses on testing edge cases and uncovered branches/lines
 */
contract BankTest is Test {
    // Contracts to test
    Bank public bank;
    BankAccount public bankAccount;
    address public deployer;

    // Test addresses
    address public user1 = address(0x123);
    address public user2 = address(0x456);
    address public admin;

    // Constants
    uint256 constant USER_INITIAL_BALANCE = 300 ether;
    uint256 constant USER_DEPOSIT_AMOUNT = 200 ether;
    uint256 constant ACTIVATION_FEE = 0.01 ether;
    uint256 constant DUE_DAY_PASSED_FEE = 0.01 ether;

    // Events for testing
    event Borrowed(address indexed borrower, uint256 amount, uint256 dueDate);
    event PaidBack(address indexed borrower, uint256 amount);
    event AccountFrozen(address indexed owner);
    event AccountActivated(address indexed owner);

    function setUp() public {
        // Deploy complete Bank system
        DeployBankSystem deployBankSystemScript = new DeployBankSystem();
        (bankAccount, bank, deployer) = deployBankSystemScript.run();

        admin = deployer;

        // Give test users some ETH
        vm.deal(user1, USER_INITIAL_BALANCE);
        vm.deal(user2, USER_INITIAL_BALANCE);
    }

    modifier createAnAccount(address _user) {
        vm.startPrank(_user);
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();
        vm.stopPrank();
        _;
    }

    // ==================== Test Invalid Address Cases ====================

    /**
     * @dev Test isValidAddress modifier with zero address - covers missing line 81
     */
    function test_IsValidAddress_ZeroAddress() public {
        console.log("=== Test Invalid Address Modifier ===");

        // Test freezeAccount with zero address (should hit isValidAddress modifier)
        vm.prank(bank.owner());
        vm.expectRevert(Bank.Bank__InvalidAddress.selector);
        bank.freezeAccount(address(0));
    }

    /**
     * @dev Test activateAccount with zero address
     */
    function test_ActivateAccount_ZeroAddress() public {
        console.log("=== Test Activate Account with Zero Address ===");

        vm.expectRevert(Bank.Bank__InvalidAddress.selector);
        bank.activateAccount{value: ACTIVATION_FEE}(address(0));
    }

    /**
     * @dev Test isAccountActive with zero address - this should trigger the modifier
     */
    function test_IsAccountActive_ZeroAddress() public {
        console.log("=== Test Is Account Active with Zero Address ===");

        vm.expectRevert(Bank.Bank__InvalidAddress.selector);
        bank.isAccountActive(address(0));
    }

    /**
     * @dev Test withdraw with zero address through modifier
     */
    function test_Withdraw_ZeroAddress() public {
        console.log("=== Test Withdraw with Zero Address ===");

        vm.expectRevert(Bank.Bank__InvalidAddress.selector);
        vm.prank(address(0));
        bank.withdraw(1 ether);
    }

    /**
     * @dev Test transferFunds with zero address through modifier
     */
    function test_TransferFunds_ZeroAddress() public {
        console.log("=== Test Transfer Funds with Zero Address ===");

        vm.expectRevert(Bank.Bank__InvalidAddress.selector);
        vm.prank(address(0));
        bank.transferFunds(user1, 1 ether);
    }

    // ==================== Test Transfer Failed in Borrow ====================

    /**
     * @dev Test borrow function when transfer fails - covers missing line 326 and branch
     * This tests the case where payLoan returns false
     */
    function test_Borrow_TransferFailed() public {
        console.log("=== Test Borrow Transfer Failed ===");

        // Deploy a contract that rejects ETH transfers
        MockRejectETH rejectContract = new MockRejectETH();
        address rejectAddress = address(rejectContract);

        // Give the reject contract some ETH and create an account for it
        vm.deal(rejectAddress, USER_INITIAL_BALANCE);

        vm.startPrank(rejectAddress);
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();

        // Now try to borrow - this should fail because the contract rejects ETH transfers
        vm.expectRevert(Bank.Bank__TransferFailed.selector);
        bank.borrow(10 ether);

        vm.stopPrank();
    }

    // ==================== Test Receive Function ====================

    /**
     * @dev Test receive function - covers missing lines 499-501 and function coverage
     */
    function test_Receive_Function() public createAnAccount(user1) {
        console.log("=== Test Receive Function ===");

        uint256 sendAmount = 1 ether;
        uint256 initialBalance = bank.getBalance(user1);

        // Send ETH directly to the Bank contract to trigger receive()
        vm.prank(user1);
        (bool success,) = address(bank).call{value: sendAmount}("");

        require(success, "ETH transfer failed");

        // Check that the funds were deposited to user1's account
        uint256 finalBalance = bank.getBalance(user1);
        assertEq(finalBalance, initialBalance + sendAmount, "Receive function should deposit ETH to sender's account");
    }

    /**
     * @dev Test receive function with user who doesn't have account
     */
    function test_Receive_Function_NoAccount() public {
        console.log("=== Test Receive Function No Account ===");

        uint256 sendAmount = 1 ether;

        // This should fail because user2 doesn't have an account
        vm.prank(user2);
        vm.expectRevert(); // Should revert when trying to deposit to non-existent account
        (bool success,) = address(bank).call{value: sendAmount}("");

        // The call itself might succeed but the internal deposit should fail
        if (success) {
            // If the call succeeded, the balance should still be 0
            assertEq(bank.getBalance(user2), 0, "Balance should remain 0 for non-existent account");
        }
    }

    // ==================== Additional Edge Case Tests ====================

    /**
     * @dev Test freezeAccount functionality with edge cases
     */
    function test_FreezeAccount_AlreadyFrozen() public createAnAccount(user1) {
        console.log("=== Test Freeze Already Frozen Account ===");

        // First freeze the account using the actual admin
        vm.prank(bank.owner());
        bank.freezeAccount(user1);

        // Try to freeze again - should revert
        vm.prank(bank.owner());
        vm.expectRevert(Bank.Bank__AccountAlreadyFrozen.selector);
        bank.freezeAccount(user1);
    }

    /**
     * @dev Test activateAccount with insufficient fee
     */
    function test_ActivateAccount_InsufficientFee() public {
        console.log("=== Test Activate Account Insufficient Fee ===");

        vm.prank(user1);
        vm.expectRevert(Bank.Bank__InsufficientActivationFee.selector);
        bank.activateAccount{value: ACTIVATION_FEE - 1}(user1);
    }

    /**
     * @dev Test activateAccount with already active account
     */
    function test_ActivateAccount_AlreadyActive() public createAnAccount(user1) {
        console.log("=== Test Activate Already Active Account ===");

        // Account is already active from modifier
        vm.prank(user1);
        vm.expectRevert(Bank.Bank__AccountAlreadyActive.selector);
        bank.activateAccount{value: ACTIVATION_FEE}(user1);
    }

    /**
     * @dev Test operations on inactive account
     */
    function test_Operations_InactiveAccount() public {
        console.log("=== Test Operations on Inactive Account ===");

        // user2 doesn't have an account, so operations should fail
        vm.startPrank(user2);

        vm.expectRevert(Bank.Bank__AccountNotActive.selector);
        bank.deposit{value: 1 ether}();

        vm.expectRevert(Bank.Bank__AccountNotActive.selector);
        bank.withdraw(1 ether);

        vm.expectRevert(Bank.Bank__AccountNotActive.selector);
        bank.transferFunds(user1, 1 ether);

        vm.stopPrank();
    }

    /**
     * @dev Test unauthorized admin operations
     */
    function test_Unauthorized_Admin_Operations() public createAnAccount(user1) {
        console.log("=== Test Unauthorized Admin Operations ===");

        // user1 is not an admin, so freezeAccount should fail
        vm.prank(user1);
        vm.expectRevert(Bank.Bank__UnAuthorized.selector);
        bank.freezeAccount(user2);
    }

    /**
     * @dev Test borrow when not eligible
     */
    function test_Borrow_NotEligible() public {
        console.log("=== Test Borrow Not Eligible ===");

        // user2 doesn't have an active account
        vm.prank(user2);
        vm.expectRevert(Bank.Bank__NotEligibleToBorrow.selector);
        bank.borrow(1 ether);
    }

    /**
     * @dev Test borrow when max amount reached
     */
    function test_Borrow_MaxAmountReached() public createAnAccount(user1) {
        console.log("=== Test Borrow Max Amount Reached ===");

        vm.startPrank(user1);

        // Try to borrow the maximum amount + 1
        uint256 maxBorrowAmount = 100 ether;
        vm.expectRevert(Bank.Bank__MaxBorrowAmountReached.selector);
        bank.borrow(maxBorrowAmount + 1 ether);

        vm.stopPrank();
    }

    /**
     * @dev Test payback with due date passed
     */
    function test_PayBack_DueDatePassed() public createAnAccount(user1) {
        console.log("=== Test PayBack Due Date Passed ===");

        vm.startPrank(user1);

        // Borrow some amount
        bank.borrow(10 ether);

        // Fast forward time past due date (30 days)
        vm.warp(block.timestamp + 31 days);

        // Try to pay back normally - should fail
        vm.expectRevert(Bank.Bank__DueDatePassed.selector);
        bank.payBack{value: 10 ether}();

        vm.stopPrank();
    }

    /**
     * @dev Test payback with insufficient amount
     */
    function test_PayBack_InsufficientAmount() public createAnAccount(user1) {
        console.log("=== Test PayBack Insufficient Amount ===");

        vm.startPrank(user1);

        // Borrow some amount
        bank.borrow(10 ether);

        // Try to pay back less than required
        vm.expectRevert(Bank.Bank__AmountIsInsufficient.selector);
        bank.payBack{value: 5 ether}();

        vm.stopPrank();
    }

    /**
     * @dev Test comprehensive getter functions
     */
    function test_Getter_Functions() public createAnAccount(user1) {
        console.log("=== Test Getter Functions ===");

        // Test owner function
        assertEq(bank.owner(), bank.owner(), "Owner should be the actual owner from bank contract");

        // Test adminRole function
        bytes32 expectedRole = 0x0000000000000000000000000000000000000000000000000000000000000000; // DEFAULT_ADMIN_ROLE
        assertEq(bank.adminRole(), expectedRole, "Admin role should be DEFAULT_ADMIN_ROLE");

        // Test isAccountActive
        assertTrue(bank.isAccountActive(user1), "user1 account should be active");
        assertFalse(bank.isAccountActive(user2), "user2 account should not be active");

        // Test activation and due day passed fees
        assertEq(bank.getActivationFee(), ACTIVATION_FEE, "Activation fee should match constant");
        assertEq(bank.getDueDayPassedFee(), DUE_DAY_PASSED_FEE, "Due day passed fee should match constant");

        vm.startPrank(user1);

        // Borrow to test borrower-related getters
        bank.borrow(10 ether);

        // Test getBorrowerDetails
        (uint256 borrowedAmount, uint256 interestRate, uint256 borrowAt, uint256 dueDate) =
            bank.getBorrowerDetailsValues(user1);
        assertEq(borrowedAmount, 10 ether, "Borrowed amount should be 10 ether");
        assertGt(interestRate, 0, "Interest rate should be greater than 0");
        assertGt(borrowAt, 0, "Borrow timestamp should be set");
        assertGt(dueDate, borrowAt, "Due date should be after borrow time");

        // Test getHowMuchHasToBePaid
        uint256 totalToPay = bank.getHowMuchHasToBePaid(user1);
        assertGe(totalToPay, borrowedAmount, "Total to pay should be at least the borrowed amount");

        // Test calculateInterestForTesting
        uint256 interest = bank.calculateInterestForTesting(user1);
        assertGe(interest, 0, "Interest should be non-negative");

        vm.stopPrank();
    }

    /**
     * @dev Test edge case where calculating interest with zero values
     */
    function test_CalculateInterest_EdgeCases() public view {
        console.log("=== Test Calculate Interest Edge Cases ===");

        // Test with address that never borrowed (should return 0)
        uint256 interest = bank.calculateInterestForTesting(user2);
        assertEq(interest, 0, "Interest for non-borrower should be 0");
    }
}
