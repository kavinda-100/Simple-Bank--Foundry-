// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {Script, console} from "forge-std/Script.sol";
import { Bank } from "../src/Bank.sol";

contract DeployBank is Script {
    function run(address bankAccountAddress) external returns (Bank, address) {
        console.log("Deploying Bank...");
        // deployer address is the sender of the transaction
        address deployer = msg.sender;
        // Start broadcasting the transaction
        vm.startBroadcast();
        Bank bank = new Bank(bankAccountAddress);
        vm.stopBroadcast();

        console.log("Bank deployed at:", address(bank));
        console.log("Deployer address:", deployer);

        return (bank, deployer);
    }
}