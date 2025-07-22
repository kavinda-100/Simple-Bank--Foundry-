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
    uint256 constant USER_INITIAL_BALANCE = 20 ether;
    uint256 constant USER_DEPOSIT_AMOUNT = 10 ether;

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


}