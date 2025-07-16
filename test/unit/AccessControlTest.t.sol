// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";
import {BankAccount} from "../../src/BankAccount.sol";

// import deployment scripts
import {DeployBank} from "../../script/DeployBank.s.sol";
import {DeployBankAccount} from "../../script/DeployBankAccount.s.sol";

/**
 * @title AccessControlTest
 * @dev Test contract to demonstrate proper role-based access control
 * @notice This test shows how Bank contract acts as admin for BankAccount
 */
contract AccessControlTest is Test {
    Bank public bank;
    BankAccount public bankAccount;

    address public deployer = address(this); // Deployer of the test contract
    address public bankAccountDeployer; // Deployer of the BankAccount contract
    address public bankDeployer; // Deployer of the Bank contract

    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public attacker = makeAddr("attacker");
    
    function setUp() public {
        // Deploy BankAccount using deployment script
        DeployBankAccount deployBankAccountScript = new DeployBankAccount();
        (bankAccount, bankAccountDeployer) = deployBankAccountScript.run();

        // Deploy Bank using deployment script
        DeployBank deployBankScript = new DeployBank();
        (bank, bankDeployer) = deployBankScript.run(address(bankAccount));


        // Give some ETH to test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(attacker, 100 ether);
        
        console.log("Setup completed!");
    }
    
    /**
     * @dev Test to verify that contracts have correct owners from deployment
     * @notice When using deployment scripts with vm.startBroadcast(), the msg.sender
     *         becomes the DefaultSender address, not the test contract address
     */
    function test_OwnersAreSame() public view {
        console.log("=== Owner Test ===");
        console.log("check the Bank and BankAccount contracts have the correct deployer address as owner");
        // Both contracts should have the same owner
        assertEq(bank.owner(), bankAccount.owner(), "Bank and BankAccount should have the same owner");

        console.log("Bank owner:", bank.owner());
        console.log("Bank deployer:", bankDeployer);
        console.log("BankAccount owner:", bankAccount.owner());
        console.log("BankAccount deployer:", bankAccountDeployer);
    }

    /**
     * @dev Test to verify role assignments are correct
     */
    function test_RoleAssignmentsAreSame() public view {
        console.log("=== Role Assignment Test ===");
        console.log("check the Bank and BankAccount contracts has the same same rolls (DEFAULT_ADMIN_ROLE)");
        assertEq(bank.adminRole(), bankAccount.adminRole(), "Bank and BankAccount should have DEFAULT_ADMIN_ROLE for deployer");
    }

    function test_DeployerIsDeployer() public view {
        console.log("=== Deployer Test ===");
        console.log("check the deployer address is same as Bank and BankAccount deployer address");
        assertEq(bankDeployer, deployer, "Bank deployer should be the test contract deployer");
        assertEq(bankAccountDeployer, deployer, "BankAccount deployer should be the test contract deployer");
    }

}