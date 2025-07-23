// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";
import {BankAccount} from "../../src/BankAccount.sol";

// import deployment scripts
import {DeployBankSystem} from "../../script/DeployBankSystem.s.sol";

contract BorrowAndPayTest is Test {
    // Contracts to test
    Bank public bank;
    BankAccount public bankAccount;
    address public deployer;

    // Addresses for test users
    address public user1 = address(0x123);
    address public user2 = address(0x456);

    // constants
    uint256 constant USER_INITIAL_BALANCE = 300 ether;
    uint256 constant USER_DEPOSIT_AMOUNT = 200 ether;
    uint256 private constant MAX_BORROW_AMOUNT = 100 ether; // Maximum amount that can be borrowed

    // Events --------------------------------------------------------------------------------------
    event Borrowed(address indexed borrower, uint256 amount, uint256 dueDate); // Event emitted when a user borrows funds
    event LoanPaid(address indexed borrower, uint256 amount); // Event emitted when a loan is paid
    event PaidBack(address indexed borrower, uint256 amount); // Event emitted when a user pays back borrowed funds
    event LoanReceived(address indexed borrower, uint256 amount); // Event emitted when a loan is received.

    function setUp() public {
        // Deploy complete Bank system using deployment script
        DeployBankSystem deployBankSystemScript = new DeployBankSystem();
        (bankAccount, bank, deployer) = deployBankSystemScript.run();

        // Give test users some ETH to work with
        vm.deal(user1, USER_INITIAL_BALANCE);
        vm.deal(user2, USER_INITIAL_BALANCE);
    }

    // ================================= Modifiers =========================================

    /**
     * @dev Modifier to create an account for a user with a predefined deposit amount.
     * It can be used in test functions to ensure the user has an account before performing actions.
     */
    modifier createAnAccount(address _user) {
        vm.startPrank(_user);
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();
        vm.stopPrank();
        _;
    }

    // ================================== Borrow Tests ==================================

    /**
     * @dev Test to verify that a user can borrow funds from the Bank contract.
     * It checks if the borrower's balance is updated correctly after borrowing.
     */
    function test_Borrow() public createAnAccount(user1) {
        // Start prank as user1 to borrow
        vm.startPrank(user1);

        // Check if the borrower has an active account
        assertTrue(bank.isAccountActive(user1), "User1's account should be active before borrowing");

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // Check if the borrower's balance is updated correctly
        assertEq(
            address(user1).balance,
            (USER_INITIAL_BALANCE - USER_DEPOSIT_AMOUNT) + borrowAmount,
            "User1's balance should be updated after borrowing"
        );

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that a borrowing user emits the Borrowed event with correct parameters.
     */
    function test_BorrowEvent() public createAnAccount(user1) {
        // Start prank as user1 to borrow
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        uint256 dueDate = block.timestamp + 30 days; // Example due date

        // Expect the Borrowed event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Borrowed(user1, borrowAmount, dueDate);

        // Call the borrow function
        bank.borrow(borrowAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that a borrowing user emits the LoanPaid event with correct parameters.
     */
    function test_LoanPaidEvent() public createAnAccount(user1) {
        // Start prank as user1 to borrow
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // Expect the LoanPaid event to be emitted when the loan is paid
        vm.expectEmit(true, true, true, true);
        emit LoanPaid(user1, borrowAmount);

        // Call the payLoan function
        bank.borrow(borrowAmount);

        vm.stopPrank();
    }

    /**
     * @dev Test is eligible for borrowing funds.
     * It checks if the user has an active account to borrow.
     */
    function test_IsEligibleForBorrowing() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // Check if the user is eligible for borrowing
        bank.borrow(5 ether);

        vm.stopPrank();
    }

    /**
     * @dev Test is eligible for borrowing funds.
     * It checks if the user has an active account to borrow if not revert with Bank__NotEligibleToBorrow.
     */
    function test_IsNotEligibleForBorrowing() public {
        // Start prank as user1
        vm.startPrank(user1);

        // Check if the user is eligible for borrowing
        vm.expectRevert(Bank.Bank__NotEligibleToBorrow.selector);
        bank.borrow(5 ether);

        vm.stopPrank();
    }

    /**
     * @dev Test if the maximum borrow amount is reached.
     * It checks if the user has an active account to borrow if not revert with Bank__MaxBorrowAmountReached.
     */
    function test_MaxBorrowAmountReached() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows the maximum amount
        bank.borrow(90 ether);

        // Check if the user can borrow more than the maximum amount
        vm.expectRevert(Bank.Bank__MaxBorrowAmountReached.selector);
        bank.borrow(20 ether);

        vm.stopPrank();
    }

    /**
     * @dev Test if the borrower details are correct after borrowing.
     */
    function test_BorrowerDetailsAfterBorrowing() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // Option 1: Using struct directly
        Bank.borrower memory borrowerDetails = bank.getBorrowerDetails(user1);
        assertEq(borrowerDetails.borrowedAmount, borrowAmount, "Borrowed amount should match");
        assertTrue(borrowerDetails.dueDate > block.timestamp, "Due date should be in the future");
        assertGt(borrowerDetails.interestRate, 0, "Interest rate should be greater than 0");
        assertEq(borrowerDetails.borrowAt, block.timestamp, "Borrow timestamp should match current timestamp");

        vm.stopPrank();
    }

    /**
     * @dev Test borrower details using destructuring (individual values).
     */
    function test_BorrowerDetailsDestructuring() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // Option 2: Using destructuring with new function
        (uint256 borrowedAmount, uint256 interestRate, uint256 borrowAt, uint256 dueDate) =
            bank.getBorrowerDetailsValues(user1);

        assertEq(borrowedAmount, borrowAmount, "Borrowed amount should match");
        assertTrue(dueDate > block.timestamp, "Due date should be in the future");
        assertGt(interestRate, 0, "Interest rate should be greater than 0");
        assertEq(borrowAt, block.timestamp, "Borrow timestamp should match current timestamp");

        vm.stopPrank();
    }

    /**
     * @dev Test if the borrow amount is greater than zero.
     * if not revert with BankAccount__LoanAmountMustBeGreaterThanZero.
     */
    function test_BorrowAmountGreaterThanZero() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // Check if the user can borrow a zero amount
        vm.expectRevert(BankAccount.BankAccount__LoanAmountMustBeGreaterThanZero.selector);
        bank.borrow(0);

        vm.stopPrank();
    }

    /**
     * @dev Test if the BankAccount contract has sufficient balance.
     * if not revert with BankAccount__InsufficientBalance.
     */
    function test_InsufficientBalance() public {
        // Start prank as user1
        vm.startPrank(user1);
        bank.createAccount{value: 10 ether}();

        // Check if the user can borrow more than their balance
        vm.expectRevert(BankAccount.BankAccount__InsufficientBalance.selector);
        bank.borrow(30 ether);

        vm.stopPrank();
    }

    // ================================== Pay Tests ==================================

    /**
     * @dev Test to verify that a user can pay back a borrowed loan.
     */
    function test_PayBackLoan() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // warp to simulate time passing
        vm.warp(block.timestamp + 15 days);

        // Check how much the user owes
        uint256 owedAmount = bank.getHowMuchHasToBePaid(user1);

        // User pays back the loan
        bank.payBack{value: owedAmount}();
        console2.log("User1 paid back the loan", owedAmount / 1e18, "ETH");
        console2.log("User1 paid back the loan", owedAmount, "wei");

        // Check if the loan is fully paid back
        (uint256 borrowedAmount, uint256 interestRate, uint256 borrowAt, uint256 dueDate) =
            bank.getBorrowerDetailsValues(user1);
        assertEq(borrowedAmount, 0, "Remaining debt should be zero");
        assertEq(interestRate, 0, "Interest rate should be zero after paying back");
        assertEq(borrowAt, 0, "Borrow timestamp should be reset after paying back");
        assertEq(dueDate, 0, "Due date should be reset after paying back");

        // check if the User1 balance is updated correctly
        assertEq(
            address(user1).balance,
            (USER_INITIAL_BALANCE - USER_DEPOSIT_AMOUNT) + borrowAmount - owedAmount,
            "User1's balance should be updated after paying back the loan"
        );
        // Check if the BankAccount contract balance is updated correctly
        assertEq(
            address(bankAccount).balance,
            (USER_DEPOSIT_AMOUNT - borrowAmount) + owedAmount,
            "BankAccount balance should be updated after paying back the loan"
        );

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that a user emits the PaidBack event with correct parameters when paying back a loan.
     */
    function test_PaidBackEvent() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // warp to simulate time passing
        vm.warp(block.timestamp + 15 days);

        // Check how much the user owes
        uint256 owedAmount = bank.getHowMuchHasToBePaid(user1);

        // Expect the PaidBack event to be emitted when the loan is paid back
        vm.expectEmit(true, false, false, true);
        emit PaidBack(user1, owedAmount);

        // User pays back the loan
        bank.payBack{value: owedAmount}();

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that a user emits the LoanReceived event with correct parameters when receiving a loan.
     */
    function test_LoanReceivedEvent() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // warp to simulate time passing
        vm.warp(block.timestamp + 15 days);

        // Check how much the user owes
        uint256 owedAmount = bank.getHowMuchHasToBePaid(user1);

        // Expect the LoanReceived event to be emitted when the loan is received
        // The event should emit the actual amount received (owedAmount), not the original borrowed amount
        vm.expectEmit(true, false, false, true);
        emit LoanReceived(user1, owedAmount);

        // User pays back the loan
        bank.payBack{value: owedAmount}();

        vm.stopPrank();
    }

    /**
     * @dev Test to verify User can not payback a loan if they don't have an active account.
     * it revert with Bank__AccountNotActive.
     */
    function test_PayBackLoanWithoutActiveAccount() public {
        // Start prank as user1
        vm.startPrank(user1);

        // Check if the user can pay back a loan without an active account
        vm.expectRevert(Bank.Bank__AccountNotActive.selector);
        bank.payBack{value: 1 ether}();

        vm.stopPrank();
    }

    /**
     * @dev Test to verify the user can not pay if the loan due date has passed.
     * it revert with Bank__DueDatePassed.
     */
    function test_PayBackLoanAfterDueDate() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // warp to simulate time passing beyond due date
        vm.warp(block.timestamp + 31 days);

        // Check how much the user owes
        uint256 owedAmount = bank.getHowMuchHasToBePaid(user1);

        // Check if the user can pay back a loan after the due date
        vm.expectRevert(Bank.Bank__DueDatePassed.selector);
        bank.payBack{value: owedAmount}();

        vm.stopPrank();
    }

    /**
     * @dev Test to Verify that user can not pay back a loan if the amount is insufficient.
     * it revert with Bank_Bank__AmountIsInsufficient.
     */
    function test_PayBackLoanWithInsufficientAmount() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // warp to simulate time passing
        vm.warp(block.timestamp + 15 days);

        // Check how much the user owes
        uint256 owedAmount = bank.getHowMuchHasToBePaid(user1);

        // Check if the user can pay back a loan with insufficient amount
        vm.expectRevert(Bank.Bank__AmountIsInsufficient.selector);
        bank.payBack{value: owedAmount - 1 ether}();

        vm.stopPrank();
    }

    // ================================== Due Day Passed Tests ==================================

    /**
     * @dev Test to verify that a user can pay back a loan with due day passed fee.
     */
    function test_PayBackLoanWithDueDayPassedFee() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // warp to simulate time passing beyond due date
        vm.warp(block.timestamp + 31 days);

        // Check how much the user owes
        uint256 owedAmount = bank.getHowMuchHasToBePaid(user1);
        uint256 dueDayPassedFee = bank.getDueDayPassedFee();

        // Check if the user can pay back a loan after the due date
        vm.expectRevert(Bank.Bank__DueDatePassed.selector);
        bank.payBack{value: owedAmount}();

        // User pays back the loan with due day passed fee
        uint256 totalAmount = owedAmount + dueDayPassedFee;
        bank.payBackWithDueDayPassedFee{value: totalAmount}();

        // Check if the loan is fully paid back
        (uint256 borrowedAmount, uint256 interestRate, uint256 borrowAt, uint256 dueDate) =
            bank.getBorrowerDetailsValues(user1);
        assertEq(borrowedAmount, 0, "Remaining debt should be zero after paying with due day passed fee");
        assertEq(interestRate, 0, "Interest rate should be zero after paying back with due day passed fee");
        assertEq(borrowAt, 0, "Borrow timestamp should be reset after paying back with due day passed fee");
        assertEq(dueDate, 0, "Due date should be reset after paying back with due day passed fee");

        // check if the User1 balance is updated correctly
        assertEq(
            address(user1).balance,
            (USER_INITIAL_BALANCE - USER_DEPOSIT_AMOUNT) + borrowAmount - owedAmount - dueDayPassedFee,
            "User1's balance should be updated after paying back the loan with due day passed fee"
        );

        // Check if the BankAccount contract balance is updated correctly
        assertEq(
            address(bankAccount).balance,
            (USER_DEPOSIT_AMOUNT - borrowAmount) + owedAmount + dueDayPassedFee,
            "BankAccount balance should be updated after paying back the loan with due day passed fee"
        );

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that a user emits the Events with correct parameters when receiving a loan payed after due date.
     */
    function test_LoanPayBackAfterDueDateEvents() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // warp to simulate time passing
        vm.warp(block.timestamp + 31 days);

        // Check how much the user owes
        uint256 owedAmount = bank.getHowMuchHasToBePaid(user1);
        uint256 dueDayPassedFee = bank.getDueDayPassedFee();

        // Check if the user can pay back a loan after the due date
        vm.expectRevert(Bank.Bank__DueDatePassed.selector);
        bank.payBack{value: owedAmount}();

        // User pays back the loan with due day passed fee
        uint256 totalAmount = owedAmount + dueDayPassedFee;

        // Expect the LoanReceived event to be emitted when the loan is received
        // The event should emit the actual amount received (owedAmount), not the original borrowed amount
        vm.expectEmit(true, false, false, true);
        emit LoanReceived(user1, owedAmount + dueDayPassedFee);

        // Expect the PaidBack event to be emitted when the loan is paid back with due day passed fee
        vm.expectEmit(true, false, false, true);
        emit PaidBack(user1, owedAmount + dueDayPassedFee);
        bank.payBackWithDueDayPassedFee{value: totalAmount}();

        vm.stopPrank();
    }

    // ================================== Interest Calculation Tests ==================================

    /**
     * @dev Test to verify that the _calculateInterest function returns 0 when no time has passed.
     */
    function test_CalculateInterest_ZeroTimeElapsed() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 10 ether
        uint256 borrowAmount = 10 ether;
        bank.borrow(borrowAmount);

        // Calculate interest immediately (no time passed)
        uint256 interest = bank.calculateInterestForTesting(user1);

        // Interest should be 0 since no time has passed
        assertEq(interest, 0, "Interest should be 0 when no time has passed");

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that the _calculateInterest function calculates interest correctly for 1 day.
     */
    function test_CalculateInterest_OneDay() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 10 ether
        uint256 borrowAmount = 10 ether;
        bank.borrow(borrowAmount);

        // Warp time by 1 day
        vm.warp(block.timestamp + 1 days);

        // Calculate interest
        uint256 interest = bank.calculateInterestForTesting(user1);

        // Expected calculation:
        // Formula: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
        // Expected: (10 ether * 500 * 1 days) / (10000 * 365 days)
        // Expected: (10e18 * 500 * 86400) / (10000 * 31536000)
        // Expected: 432000000000000000000000000 / 315360000000000 = 1369863013698630 wei ≈ 0.00136986... ether
        uint256 expectedInterest = (borrowAmount * 500 * 1 days) / (10000 * 365 days);

        assertEq(interest, expectedInterest, "Interest calculation for 1 day should match expected value");
        // Also verify the approximate value for better understanding
        assertApproxEqRel(
            interest, 1369863013698630, 1e15, "Interest should be approximately 0.00136986 ether for 1 day"
        );

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that the _calculateInterest function calculates interest correctly for 30 days.
     */
    function test_CalculateInterest_ThirtyDays() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 20 ether
        uint256 borrowAmount = 20 ether;
        bank.borrow(borrowAmount);

        // Warp time by 30 days
        vm.warp(block.timestamp + 30 days);

        // Calculate interest
        uint256 interest = bank.calculateInterestForTesting(user1);

        // Expected calculation:
        // Formula: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
        // Expected: (20 ether * 500 * 30 days) / (10000 * 365 days)
        uint256 expectedInterest = (borrowAmount * 500 * 30 days) / (10000 * 365 days);

        assertEq(interest, expectedInterest, "Interest calculation for 30 days should match expected value");
        // Verify approximate value: 30/365 * 5% * 20 ether ≈ 0.0822 ether
        assertApproxEqRel(
            interest, 82191780821917808, 1e15, "Interest should be approximately 0.0822 ether for 30 days"
        );

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that the _calculateInterest function calculates interest correctly for 1 year.
     */
    function test_CalculateInterest_OneYear() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 50 ether (less than max to avoid hitting the limit)
        uint256 borrowAmount = 50 ether;
        bank.borrow(borrowAmount);

        // Warp time by 1 year (365 days)
        vm.warp(block.timestamp + 365 days);

        // Calculate interest
        uint256 interest = bank.calculateInterestForTesting(user1);

        // Expected calculation:
        // Formula: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
        // Expected: (50 ether * 500 * 365 days) / (10000 * 365 days)
        // Expected: 50 ether * 500 / 10000 = 50 ether * 0.05 = 2.5 ether
        uint256 expectedInterest = (borrowAmount * 500) / 10000; // Simplified for 1 year

        assertEq(interest, expectedInterest, "Interest calculation for 1 year should match expected value");
        assertEq(
            interest, 2.5 ether, "Interest should be exactly 2.5 ether for 50 ether borrowed for 1 year at 5% rate"
        );

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that the _calculateInterest function calculates interest correctly for 15 days.
     * This matches the scenario used in other tests.
     */
    function test_CalculateInterest_FifteenDays() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows 5 ether (same as other tests)
        uint256 borrowAmount = 5 ether;
        bank.borrow(borrowAmount);

        // Warp time by 15 days (same as payback tests)
        vm.warp(block.timestamp + 15 days);

        // Calculate interest
        uint256 interest = bank.calculateInterestForTesting(user1);

        // Expected calculation:
        // Formula: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
        // Expected: (5 ether * 500 * 15 days) / (10000 * 365 days)
        uint256 expectedInterest = (borrowAmount * 500 * 15 days) / (10000 * 365 days);

        assertEq(interest, expectedInterest, "Interest calculation for 15 days should match expected value");

        // Verify this matches what getHowMuchHasToBePaid returns minus principal
        uint256 totalOwed = bank.getHowMuchHasToBePaid(user1);
        uint256 interestFromTotal = totalOwed - borrowAmount;
        assertEq(interest, interestFromTotal, "Interest calculated directly should match interest from total owed");

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that the _calculateInterest function returns 0 for zero principal.
     */
    function test_CalculateInterest_ZeroPrincipal() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // Don't borrow anything (principal remains 0)
        // Warp time by 30 days
        vm.warp(block.timestamp + 30 days);

        // Calculate interest for a user who hasn't borrowed
        uint256 interest = bank.calculateInterestForTesting(user1);

        // Interest should be 0 since principal is 0
        assertEq(interest, 0, "Interest should be 0 when principal is 0");

        vm.stopPrank();
    }

    /**
     * @dev Test to verify that the _calculateInterest function scales correctly with different principal amounts.
     */
    function test_CalculateInterest_DifferentPrincipalAmounts() public {
        // Test with user1: 1 ether
        vm.startPrank(user1);
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();
        bank.borrow(1 ether);
        vm.stopPrank();

        // Test with user2: 50 ether
        vm.startPrank(user2);
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();
        bank.borrow(50 ether);
        vm.stopPrank();

        // Warp time by 10 days for both
        vm.warp(block.timestamp + 10 days);

        // Calculate interest for both users
        uint256 interest1 = bank.calculateInterestForTesting(user1);
        uint256 interest2 = bank.calculateInterestForTesting(user2);

        // Interest should scale linearly with principal
        // user2 borrowed 50x more, so interest should be 50x more (with small rounding tolerance)
        assertApproxEqRel(interest2, interest1 * 50, 1e12, "Interest should scale linearly with principal amount");

        // Verify the actual calculations (using separate variables to avoid precision issues)
        uint256 principal1 = 1 ether;
        uint256 principal2 = 50 ether;
        uint256 rate = 500;
        uint256 timeElapsed = 10 days;
        uint256 basisPoints = 10000;
        uint256 secondsInYear = 365 days;

        uint256 expectedInterest1 = (principal1 * rate * timeElapsed) / (basisPoints * secondsInYear);
        uint256 expectedInterest2 = (principal2 * rate * timeElapsed) / (basisPoints * secondsInYear);

        assertEq(interest1, expectedInterest1, "Interest for 1 ether should match expected");
        assertEq(interest2, expectedInterest2, "Interest for 50 ether should match expected");
    }

    /**
     * @dev Test to verify interest calculation precision with small amounts and short durations.
     */
    function test_CalculateInterest_SmallAmountShortDuration() public createAnAccount(user1) {
        // Start prank as user1
        vm.startPrank(user1);

        // User borrows a small amount: 0.1 ether
        uint256 borrowAmount = 0.1 ether;
        bank.borrow(borrowAmount);

        // Warp time by 1 hour
        vm.warp(block.timestamp + 1 hours);

        // Calculate interest for user1
        uint256 interest = bank.calculateInterestForTesting(user1);

        // Expected calculation:
        // Formula: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
        // Expected: (0.1 ether * 500 * 1 hours) / (10000 * 365 days)
        uint256 expectedInterest = (borrowAmount * 500 * 1 hours) / (10000 * 365 days);

        assertEq(interest, expectedInterest, "Interest calculation for small amount and short duration should match");

        vm.stopPrank();
    }
}
