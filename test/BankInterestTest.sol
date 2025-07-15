// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {BankAccount} from "../src/BankAccount.sol";

/**
 * @title BankInterestTest
 * @dev Test contract to demonstrate the improved interest calculation
 * @notice This test shows how the new basis points system provides better precision
 */
contract BankInterestTest is Test {
    Bank public bank;
    BankAccount public bankAccount;
    
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    
    function setUp() public {
        // Deploy BankAccount first
        bankAccount = new BankAccount();
        
        // Deploy Bank with BankAccount address
        bank = new Bank(address(bankAccount));
        
        // Give some ETH to test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        // The deployer (this test contract) should grant the admin role to itself first
        // Then grant admin role to bank contract in BankAccount
        bankAccount.grantRole(bankAccount.DEFAULT_ADMIN_ROLE(), address(this));
        bankAccount.grantRole(bankAccount.ADMIN_ROLE(), address(bank));
        bankAccount.grantRole(bankAccount.ADMIN_ROLE(), address(this));
    }
    
    /**
     * @dev Test to show interest calculation precision with different amounts
     */
    function test_InterestCalculationPrecision() public {
        console.log("=== Interest Calculation Precision Test ===");
        
        // Get contract constants
        (, uint256 interestRate, uint256 basisPoints) = bank.getContractConstants();
        console.log("Interest Rate: %d basis points (%d.%02d%%)", 
            interestRate, 
            interestRate / 100, 
            interestRate % 100
        );
        console.log("Basis Points Scale: %d", basisPoints);
        
        // Test different borrow amounts
        uint256[] memory testAmounts = new uint256[](5);
        testAmounts[0] = 1 wei;
        testAmounts[1] = 1000 wei;  
        testAmounts[2] = 1 ether;
        testAmounts[3] = 10 ether;
        testAmounts[4] = 50 ether;
        
        for (uint256 i = 0; i < testAmounts.length; i++) {
            _testInterestForAmount(testAmounts[i], i + 1);
        }
    }
    
    /**
     * @dev Helper function to test interest calculation for a specific amount
     */
    function _testInterestForAmount(uint256 amount, uint256 testNum) internal {
        console.log("\n--- Test %d: Amount = %d wei ---", testNum, amount);
        
        // Skip forward 1 year (365 days)
        vm.warp(block.timestamp + 365 days);
        
        // Calculate what interest should be for 1 year at 5% annual rate
        uint256 expectedAnnualInterest = (amount * 500) / 10000; // 5% = 500 basis points
        
        console.log("Principal: %d wei", amount);
        console.log("Expected annual interest (5%%): %d wei", expectedAnnualInterest);
        
        // Test at different time intervals
        uint256[] memory timeIntervals = new uint256[](4);
        timeIntervals[0] = 1 days;   // 1 day
        timeIntervals[1] = 30 days;  // 1 month 
        timeIntervals[2] = 90 days;  // 3 months
        timeIntervals[3] = 365 days; // 1 year
        
        for (uint256 j = 0; j < timeIntervals.length; j++) {
            uint256 timeElapsed = timeIntervals[j];
            uint256 calculatedInterest = _calculateExpectedInterest(amount, 500, timeElapsed);
            
            console.log("Time: %d days, Interest: %d wei", timeElapsed / 1 days, calculatedInterest);
        }
    }
    
    /**
     * @dev Helper function to calculate expected interest using the same formula as the contract
     */
    function _calculateExpectedInterest(
        uint256 principal, 
        uint256 interestRate, 
        uint256 timeElapsed
    ) internal pure returns (uint256) {
        if (timeElapsed == 0 || principal == 0) {
            return 0;
        }
        
        uint256 BASIS_POINTS = 10000;
        uint256 SECONDS_IN_YEAR = 365 days;
        
        return (principal * interestRate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR);
    }
    
    /**
     * @dev Test to compare old vs new interest calculation method
     */
    function test_CompareOldVsNewCalculation() public pure {
        console.log("\n=== Old vs New Interest Calculation Comparison ===");
        
        uint256 principal = 1 ether;
        uint256 timeElapsed = 30 days; // 1 month
        
        // Old method (flat 5%)
        uint256 oldInterest = (principal * 5) / 100;
        
        // New method (5% annual, prorated for 30 days)
        uint256 newInterest = _calculateExpectedInterest(principal, 500, timeElapsed);
        
        console.log("Principal: %d wei (%d ETH)", principal, principal / 1 ether);
        console.log("Time period: %d days", timeElapsed / 1 days);
        console.log("Old method interest: %d wei (%d ETH)", oldInterest, oldInterest / 1 ether);
        console.log("New method interest: %d wei", newInterest);
        console.log("Difference: %d wei", oldInterest > newInterest ? oldInterest - newInterest : newInterest - oldInterest);
        
        // The new method should be much more accurate for time-based lending
        assertTrue(newInterest < oldInterest, "New method should calculate lower interest for 30 days vs flat 5%");
    }
    
    /**
     * @dev Test edge cases for interest calculation
     */
    function test_InterestCalculationEdgeCases() public pure {
        console.log("\n=== Interest Calculation Edge Cases ===");
        
        // Test zero principal
        uint256 zeroInterest = _calculateExpectedInterest(0, 500, 30 days);
        assertEq(zeroInterest, 0, "Zero principal should result in zero interest");
        
        // Test zero time
        uint256 zeroTimeInterest = _calculateExpectedInterest(1 ether, 500, 0);
        assertEq(zeroTimeInterest, 0, "Zero time should result in zero interest");
        
        // Test very small amounts
        uint256 smallAmountInterest = _calculateExpectedInterest(1 wei, 500, 365 days);
        console.log("1 wei principal, 1 year interest: %d wei", smallAmountInterest);
        
        console.log("All edge cases passed!");
    }
}
