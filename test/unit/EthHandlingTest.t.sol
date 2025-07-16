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
    
    // Addresses for test users
    address public user1 = address(0x123);
    address public user2 = address(0x456);

    // Events ---------------------------------------------------------------------------------------------
    event Deposit(address indexed owner, uint256 amount); // Event emitted when a deposit is made
    
    function setUp() public {
        // Deploy BankAccount using deployment script
        DeployBankAccount deployBankAccountScript = new DeployBankAccount();
        address bankAccountDeployer;
        (bankAccount, bankAccountDeployer) = deployBankAccountScript.run();

        // Deploy Bank using deployment script
        DeployBank deployBankScript = new DeployBank();
        address bankDeployer;
        (bank, bankDeployer) = deployBankScript.run(address(bankAccount));
        
        // Give test users some ETH to work with
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
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
        bankAccount.deposit{value: depositAmount}(user1);
        
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
        bankAccount.deposit{value: 0}(user1);
        
        vm.stopPrank();
    }
    
   
}
