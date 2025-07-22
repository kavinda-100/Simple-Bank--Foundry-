// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {Script, console} from "forge-std/Script.sol";
import { BankAccount } from "../../src/BankAccount.sol";

contract DeployBankAccount is Script {
    function run() external returns (BankAccount, address) {
        console.log("Deploying BankAccount...");
        // deployer address is the sender of the transaction
        address deployer = msg.sender;
        // Start broadcasting the transaction
        vm.startBroadcast();
        BankAccount bankAccount = new BankAccount();
        vm.stopBroadcast();
        
        console.log("BankAccount deployed at:", address(bankAccount));
        console.log("Deployer address:", deployer);

        return (bankAccount, deployer);
    }
}