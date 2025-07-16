// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";
import {BankAccount} from "../../src/BankAccount.sol";

/**
 * @title AccessControlTest
 * @dev Test contract to demonstrate proper role-based access control
 * @notice This test shows how Bank contract acts as admin for BankAccount
 */
contract AccessControlTest is Test {
    Bank public bank;
    BankAccount public bankAccount;
    
    address public deployer = address(this);
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public attacker = makeAddr("attacker");
    
    function setUp() public {
        // Deploy BankAccount first
        console.log("Deploying BankAccount...");
        bankAccount = new BankAccount();
        
        // Deploy Bank with BankAccount address
        console.log("Deploying Bank...");
        bank = new Bank(address(bankAccount));
        
        // Give some ETH to test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(attacker, 100 ether);
        
        console.log("Setup completed!");
    }
    
    /**
     * @dev Test to verify role assignments are correct
     */
    function test_OwnersAreSame() public view {
        console.log("=== Role Assignment Test ===");
        console.log("check the Bank and BankAccount contracts has the same deployer address as owner");
        assertEq(bank.owner(), deployer, "Bank owner should be deployer");
        assertEq(bankAccount.owner(), deployer, "BankAccount owner should be deployer");
    }

    /**
     * @dev Test to verify role assignments are correct
     */
    function test_RoleAssignmentsAreSame() public view {
        console.log("=== Role Assignment Test ===");
        console.log("check the Bank and BankAccount contracts has the same same rolls (DEFAULT_ADMIN_ROLE)");
        assertEq(bank.adminRole(), bankAccount.adminRole(), "Bank and BankAccount should have DEFAULT_ADMIN_ROLE for deployer");
    }

}