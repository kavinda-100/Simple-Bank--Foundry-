// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BankAccount} from "../src/BankAccount.sol";
import {Bank} from "../src/Bank.sol";

contract DeployBankSystem is Script {
    function run() external returns (BankAccount, Bank, address) {
        console.log("Deploying complete Bank system...");
        
        address deployer = msg.sender;
        vm.startBroadcast();
        
        // 1. Deploy BankAccount
        console.log("1. Deploying BankAccount...");
        BankAccount bankAccount = new BankAccount();
        console.log("BankAccount deployed at:", address(bankAccount));
        
        // 2. Deploy Bank
        console.log("2. Deploying Bank...");
        Bank bank = new Bank(address(bankAccount));
        console.log("Bank deployed at:", address(bank));
        
        // 3. Grant admin role to Bank contract
        console.log("3. Granting admin role to Bank contract...");
        bankAccount.grantAdminRoleToBank(address(bank));
        console.log("Admin role granted successfully");
        
        vm.stopBroadcast();
        
        console.log("===================================");
        console.log("Deployment Summary:");
        console.log("BankAccount:", address(bankAccount));
        console.log("Bank:", address(bank));
        console.log("Deployer:", deployer);
        console.log("===================================");
        
        return (bankAccount, bank, deployer);
    }
}
