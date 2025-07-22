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

        // get the borrower's details
        // console2.log("Borrower details:");
        // (uint256 borrowedAmount,
        // uint256 interestRate,
        // uint256 borrowAt,
        // uint256 dueDate) = bank.getBorrowerDetails(user1);
        // console2.log("User1's borrowed amount:", borrowedAmount);
        // console2.log("User1's interest rate:", interestRate);
        // console2.log("User1's borrow timestamp:", borrowAt);
        // console2.log("User1's due date:", dueDate);

        vm.stopPrank();
    }
}