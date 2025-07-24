// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";
import {BankAccount} from "../../src/BankAccount.sol";

/**
 * @title BankIntegrationTest
 * @notice Integration tests for Bank and BankAccount interaction
 * @dev Tests complex workflows involving multiple contracts and users
 */
contract BankIntegrationTest is Test {
    Bank public bank;
    BankAccount public bankAccount;

    address public admin;
    address public user1;
    address public user2;
    address public user3;

    uint256 public constant ACTIVATION_FEE = 0.01 ether;
    uint256 public constant MINIMUM_BALANCE = 1 ether;

    function setUp() public {
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy contracts
        vm.startPrank(admin);
        bankAccount = new BankAccount();
        bank = new Bank(address(bankAccount));
        bankAccount.grantAdminRoleToBank(address(bank));
        vm.stopPrank();

        // Fund users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        // Fund bank for borrowing
        vm.deal(address(bank), 1000 ether);
    }

    /**
     * @notice Test complete lending cycle with multiple users
     * @dev Tests the full workflow: create accounts, deposit, borrow, transfer, payback
     */
    function test_Integration_CompleteLendingCycle() public {
        // users amounts
        uint256 user1Deposit = 3 ether;
        uint256 user2Deposit = 2 ether;
        uint256 user3Deposit = 5 ether;

        // Phase 1: Account creation for all users
        vm.prank(user1);
        bank.createAccount{value: user1Deposit + ACTIVATION_FEE}();

        vm.prank(user2);
        bank.createAccount{value: user2Deposit + ACTIVATION_FEE}();

        vm.prank(user3);
        bank.createAccount{value: user3Deposit + ACTIVATION_FEE}();

        // Verify initial balances (includes activation fee in balance)
        assertEq(bank.getBalance(user1), user1Deposit + ACTIVATION_FEE);
        assertEq(bank.getBalance(user2), user2Deposit + ACTIVATION_FEE);
        assertEq(bank.getBalance(user3), user3Deposit + ACTIVATION_FEE);

        // Phase 2: User1 borrows funds
        vm.prank(user1);
        bank.borrow(1 ether);

        // Verify borrowing state
        Bank.borrower memory user1Loan = bank.getBorrowerDetails(user1);
        assertEq(user1Loan.borrowedAmount, 1 ether);
        assertGt(user1Loan.dueDate, block.timestamp);

        // Phase 3: Cross-user transfers
        vm.prank(user3);
        bank.transferFunds(user2, 1 ether); // User3 transfers 1 ether to User2

        // Verify balances after transfer
        assertEq(bank.getBalance(user3), (user3Deposit + ACTIVATION_FEE) - 1 ether);
        assertEq(bank.getBalance(user2), (user2Deposit + ACTIVATION_FEE) + 1 ether);

        // Phase 4: Additional deposits
        vm.prank(user2);
        bank.deposit{value: 1 ether}(); // User2 deposits 1 ether

        assertEq(bank.getBalance(user2), (user2Deposit + ACTIVATION_FEE) + 1 ether + 1 ether); // Previous balance + transfer + deposit

        // Phase 5: Loan repayment
        vm.warp(block.timestamp + 1 days); // Add some time for interest
        uint256 totalOwed = bank.getHowMuchHasToBePaid(user1);
        vm.prank(user1);
        bank.payBack{value: totalOwed}();

        // Verify loan is cleared
        Bank.borrower memory user1LoanAfter = bank.getBorrowerDetails(user1);
        assertEq(user1LoanAfter.borrowedAmount, 0);

        // Phase 6: Withdrawals
        uint256 user3BalanceBefore = bank.getBalance(user3);
        vm.prank(user3);
        bank.withdraw(1 ether);
        console2.log("User3 balance after withdrawal:", bank.getBalance(user3));

        assertEq(bank.getBalance(user3), user3BalanceBefore - 1 ether);
    }

    /**
     * @notice Test concurrent borrowing by multiple users
     * @dev Ensures the system can handle multiple active loans
     */
    function test_Integration_ConcurrentBorrowing() public {
        // Setup accounts
        vm.prank(user1);
        bank.createAccount{value: 5 ether + ACTIVATION_FEE}();

        vm.prank(user2);
        bank.createAccount{value: 5 ether + ACTIVATION_FEE}();

        // Both users borrow simultaneously
        vm.prank(user1);
        bank.borrow(2 ether);

        vm.prank(user2);
        bank.borrow(3 ether);

        // Verify both loans are active
        Bank.borrower memory user1Loan = bank.getBorrowerDetails(user1);
        Bank.borrower memory user2Loan = bank.getBorrowerDetails(user2);

        assertEq(user1Loan.borrowedAmount, 2 ether);
        assertEq(user2Loan.borrowedAmount, 3 ether);

        // Fast forward time to accrue interest
        vm.warp(block.timestamp + 30 days);

        // Calculate interests
        uint256 user1Interest = bank.calculateInterestForTesting(user1);
        uint256 user2Interest = bank.calculateInterestForTesting(user2);

        assertGt(user1Interest, 0);
        assertGt(user2Interest, 0);
        assertGt(user2Interest, user1Interest); // User2 borrowed more, so more interest
    }

    /**
     * @notice Test account freeze and reactivation workflow
     * @dev Tests admin controls over user accounts
     */
    function test_Integration_AccountManagement() public {
        // Create user account
        vm.prank(user1);
        bank.createAccount{value: 3 ether + ACTIVATION_FEE}();

        assertTrue(bank.isAccountActive(user1));

        // Admin freezes account
        vm.prank(admin);
        bank.freezeAccount(user1);

        assertFalse(bank.isAccountActive(user1));

        // User should not be able to perform operations
        vm.prank(user1);
        vm.expectRevert(Bank.Bank__NotEligibleToBorrow.selector);
        bank.borrow(1 ether);

        vm.prank(user1);
        vm.expectRevert(Bank.Bank__AccountNotActive.selector);
        bank.withdraw(1 ether);

        // Admin reactivates account
        vm.prank(user1);
        bank.activateAccount{value: ACTIVATION_FEE}(user1);

        assertTrue(bank.isAccountActive(user1));

        // User can now perform operations again
        vm.prank(user1);
        bank.borrow(1 ether); // Should succeed
    }

    /**
     * @notice Test system behavior under stress conditions
     * @dev Tests edge cases and high-volume operations
     */
    function test_Integration_StressTest() public {
        address[] memory users = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            users[i] = makeAddr(string(abi.encodePacked("stressUser", i)));
            vm.deal(users[i], 20 ether);
        }

        // Create accounts for all stress test users
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(users[i]);
            bank.createAccount{value: 10 ether + ACTIVATION_FEE}();
        }

        // Perform multiple operations rapidly
        for (uint256 i = 0; i < 5; i++) {
            // Each user borrows
            vm.prank(users[i]);
            bank.borrow((i + 1) * 1 ether);

            // Transfers between users
            if (i < 4) {
                vm.prank(users[i]);
                bank.transferFunds(users[i + 1], 0.5 ether);
            }
        }

        // Verify system integrity after stress operations
        for (uint256 i = 0; i < 5; i++) {
            assertTrue(bank.isAccountActive(users[i]));
            assertGt(bank.getBalance(users[i]), 0);

            Bank.borrower memory loan = bank.getBorrowerDetails(users[i]);
            assertEq(loan.borrowedAmount, (i + 1) * 1 ether);
        }
    }

    /**
     * @notice Test complex scenarios with time-based operations
     * @dev Tests loan due dates, interest accrual, and late payment fees
     */
    function test_Integration_TimeBasedOperations() public {
        // Setup
        vm.prank(user1);
        bank.createAccount{value: 5 ether + ACTIVATION_FEE}();

        // Borrow funds
        vm.prank(user1);
        bank.borrow(2 ether);

        Bank.borrower memory loan = bank.getBorrowerDetails(user1);
        uint256 originalDueDate = loan.dueDate;

        // Fast forward to just before due date
        vm.warp(originalDueDate - 1 days);

        // Normal payback should work
        uint256 totalOwed = bank.getHowMuchHasToBePaid(user1);
        vm.prank(user1);
        bank.payBack{value: totalOwed}();

        // Verify loan is cleared
        Bank.borrower memory loanAfter = bank.getBorrowerDetails(user1);
        assertEq(loanAfter.borrowedAmount, 0);

        // Test late payment scenario
        vm.prank(user1);
        bank.borrow(1 ether);

        loan = bank.getBorrowerDetails(user1);

        // Fast forward past due date
        vm.warp(loan.dueDate + 1 days);

        // Should require late fee
        uint256 latePaymentAmount = bank.getHowMuchHasToBePaid(user1) + bank.getDueDayPassedFee();
        vm.prank(user1);
        bank.payBackWithDueDayPassedFee{value: latePaymentAmount}();

        // Verify loan is cleared
        loanAfter = bank.getBorrowerDetails(user1);
        assertEq(loanAfter.borrowedAmount, 0);
    }
}
