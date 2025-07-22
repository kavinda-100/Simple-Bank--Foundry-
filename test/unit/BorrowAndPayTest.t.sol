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
        assertEq(address(user1).balance, (USER_INITIAL_BALANCE - USER_DEPOSIT_AMOUNT) + borrowAmount, "User1's balance should be updated after borrowing");

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
        (uint256 borrowedAmount,
         uint256 interestRate,
         uint256 borrowAt,
         uint256 dueDate) = bank.getBorrowerDetailsValues(user1);
         
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


}