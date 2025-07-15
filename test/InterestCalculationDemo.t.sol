// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

/**
 * @title InterestCalculationDemo
 * @dev Simple test to demonstrate the interest calculation improvements
 * @notice This shows the difference between the old and new interest calculation methods
 */
contract InterestCalculationDemo is Test {
    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant SECONDS_IN_YEAR = 365 days;
    uint256 private constant INTEREST_RATE = 500; // 5.00% in basis points
    
    /**
     * @dev Simulates the old interest calculation method
     */
    function calculateOldInterest(uint256 principal) internal pure returns (uint256) {
        return (principal * 5) / 100; // Flat 5%
    }
    
    /**
     * @dev Simulates the new time-based interest calculation method
     */
    function calculateNewInterest(
        uint256 principal, 
        uint256 interestRate, 
        uint256 timeElapsed
    ) internal pure returns (uint256) {
        if (timeElapsed == 0 || principal == 0) {
            return 0;
        }
        
        return (principal * interestRate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR);
    }
    
    /**
     * @dev Test to demonstrate precision improvements
     */
    function test_InterestCalculationComparison() public pure {
        console.log("=== Interest Calculation Comparison ===");
        console.log("Interest Rate: %d basis points (5.00%%)", INTEREST_RATE);
        console.log("Basis Points Scale: %d", BASIS_POINTS);
        console.log("");
        
        // Test different amounts and time periods
        uint256[] memory testAmounts = new uint256[](4);
        testAmounts[0] = 1 wei;
        testAmounts[1] = 1000 wei;
        testAmounts[2] = 1 ether;
        testAmounts[3] = 10 ether;
        
        uint256[] memory timePeriods = new uint256[](4);
        timePeriods[0] = 1 days;
        timePeriods[1] = 30 days;
        timePeriods[2] = 90 days;
        timePeriods[3] = 365 days;
        
        string[] memory timeLabels = new string[](4);
        timeLabels[0] = "1 day";
        timeLabels[1] = "30 days";
        timeLabels[2] = "90 days";
        timeLabels[3] = "365 days";
        
        for (uint256 i = 0; i < testAmounts.length; i++) {
            console.log("--- Principal: %d wei ---", testAmounts[i]);
            console.log("Old method (flat 5%%): %d wei", calculateOldInterest(testAmounts[i]));
            
            for (uint256 j = 0; j < timePeriods.length; j++) {
                uint256 newInterest = calculateNewInterest(testAmounts[i], INTEREST_RATE, timePeriods[j]);
                console.log("New method (%s): %d wei", timeLabels[j], newInterest);
            }
            console.log("");
        }
    }
    
    /**
     * @dev Test edge cases
     */
    function test_EdgeCases() public pure {
        console.log("=== Edge Cases ===");
        
        // Zero principal
        uint256 zeroInterest = calculateNewInterest(0, INTEREST_RATE, 30 days);
        console.log("Zero principal interest: %d wei", zeroInterest);
        
        // Zero time
        uint256 zeroTimeInterest = calculateNewInterest(1 ether, INTEREST_RATE, 0);
        console.log("Zero time interest: %d wei", zeroTimeInterest);
        
        // Very small amounts
        uint256 oneWeiYear = calculateNewInterest(1 wei, INTEREST_RATE, 365 days);
        console.log("1 wei for 1 year: %d wei", oneWeiYear);
        
        // Large amounts
        uint256 largeAmount = calculateNewInterest(100 ether, INTEREST_RATE, 365 days);
        console.log("100 ETH for 1 year: %d wei (%d ETH)", largeAmount, largeAmount / 1 ether);
    }
    
    /**
     * @dev Test precision with basis points vs percentage
     */
    function test_PrecisionComparison() public pure {
        console.log("=== Precision Comparison ===");
        
        uint256 principal = 1000 wei;
        uint256 timeElapsed = 30 days;
        
        // Old method (5% flat)
        uint256 oldMethod = (principal * 5) / 100;
        
        // New method with basis points
        uint256 newMethod = calculateNewInterest(principal, INTEREST_RATE, timeElapsed);
        
        // What 5% annually should be for 30 days
        uint256 expectedFor30Days = (principal * 5 * 30) / (100 * 365);
        
        console.log("Principal: %d wei", principal);
        console.log("Time period: 30 days");
        console.log("Old method (flat 5%%): %d wei", oldMethod);
        console.log("New method (5%% annual, 30 days): %d wei", newMethod);
        console.log("Expected (5%% * 30/365): %d wei", expectedFor30Days);
        
        console.log("");
        console.log("The new method is %s accurate for time-based lending",
            newMethod == expectedFor30Days ? "more" : "less");
    }
}
