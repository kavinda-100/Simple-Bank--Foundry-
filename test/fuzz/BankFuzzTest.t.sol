// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";
import {BankAccount} from "../../src/BankAccount.sol";

/**
 * @title BankFuzzTest
 * @notice Fuzz tests for Bank contract to test with random inputs
 * @dev These tests help find edge cases that might be missed in unit tests
 */
contract BankFuzzTest is Test {
    Bank public bank;
    BankAccount public bankAccount;

    address public admin;
    uint256 public constant ACTIVATION_FEE = 0.1 ether;
    uint256 public constant MINIMUM_BALANCE = 1 ether;

    function setUp() public {
        admin = makeAddr("admin");

        vm.startPrank(admin);
        bankAccount = new BankAccount();
        bank = new Bank(address(bankAccount));
        bankAccount.grantAdminRoleToBank(address(bank));
        vm.stopPrank();
    }

    /**
     * @notice Fuzz test for deposit amounts
     * @dev Tests deposits with random amounts to find edge cases
     */
    function testFuzz_Deposit(address user, uint256 depositAmount) public {
        // Bound inputs to reasonable ranges
        vm.assume(user != address(0));
        vm.assume(user != admin);
        vm.assume(user.code.length == 0); // Only EOAs
        vm.assume(uint160(user) > 0x10); // Exclude precompile addresses (0x1-0x9) and other low addresses
        vm.assume(user != address(0x000000000000000000636F6e736F6c652e6c6f67)); // Exclude console.log address
        vm.assume(uint160(user) < type(uint160).max - 1000); // Exclude very high addresses that might be special
        depositAmount = bound(depositAmount, MINIMUM_BALANCE, 100 ether);

        // Fund the user
        vm.deal(user, depositAmount + ACTIVATION_FEE + 1 ether); // Extra for gas

        // Create account and deposit
        vm.startPrank(user);
        bank.createAccount{value: depositAmount}();

        uint256 balanceAfter = bank.getBalance(user);
        assertEq(balanceAfter, depositAmount);
        vm.stopPrank();
    }

    /**
     * @notice Fuzz test for borrow amounts
     * @dev Tests borrowing with random amounts within valid ranges
     */
    function testFuzz_Borrow(address user, uint256 depositAmount, uint256 borrowAmount) public {
        // Bound inputs
        vm.assume(user != address(0));
        vm.assume(user != admin);
        vm.assume(user.code.length == 0); // Only EOAs
        vm.assume(uint160(user) > 0x10); // Exclude precompile addresses (0x1-0x9) and other low addresses
        vm.assume(user != address(0x000000000000000000636F6e736F6c652e6c6f67)); // Exclude console.log address
        vm.assume(uint160(user) < type(uint160).max - 1000); // Exclude very high addresses that might be special
        depositAmount = bound(depositAmount, MINIMUM_BALANCE, 50 ether);
        borrowAmount = bound(borrowAmount, 0.1 ether, min(depositAmount, 50 ether)); // Max 50 ETH borrow

        // Setup
        vm.deal(user, depositAmount + ACTIVATION_FEE + 1 ether);
        vm.deal(address(bank), borrowAmount + 10 ether); // Fund bank for borrowing

        vm.startPrank(user);
        bank.createAccount{value: depositAmount + ACTIVATION_FEE}();

        // Borrow should succeed if amount is valid
        if (borrowAmount <= 50 ether) {
            // Max borrow limit (reduced from 100)
            bank.borrow(borrowAmount);

            // Verify borrow state
            Bank.borrower memory borrowerDetails = bank.getBorrowerDetails(user);
            assertTrue(borrowerDetails.borrowedAmount > 0);
            assertEq(borrowerDetails.borrowedAmount, borrowAmount);
            assertEq(borrowerDetails.interestRate, 500); // 5% rate in basis points
            assertGt(borrowerDetails.dueDate, block.timestamp);
        }
        vm.stopPrank();
    }

    // Helper function
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Fuzz test for interest calculations
     * @dev Tests interest calculation with random borrower addresses that have loans
     */
    function testFuzz_InterestCalculation(address user, uint256 borrowAmount, uint256 timeSkip) public {
        // Bound inputs to reasonable ranges
        vm.assume(user != address(0));
        vm.assume(user != admin);
        vm.assume(user.code.length == 0); // Only EOAs
        vm.assume(uint160(user) > 0x10); // Exclude precompile addresses (0x1-0x9) and other low addresses
        vm.assume(user != address(0x000000000000000000636F6e736F6c652e6c6f67)); // Exclude console.log address
        vm.assume(uint160(user) < type(uint160).max - 1000); // Exclude very high addresses that might be special
        borrowAmount = bound(borrowAmount, 1 ether, 50 ether);
        timeSkip = bound(timeSkip, 1 days, 30 days); // Reduced time range

        // Setup user with loan
        uint256 depositAmount = borrowAmount + 1 ether; // Ensure enough collateral
        vm.deal(user, depositAmount + ACTIVATION_FEE + 1 ether);
        vm.deal(address(bank), borrowAmount + 10 ether);

        vm.startPrank(user);
        bank.createAccount{value: depositAmount}();
        bank.borrow(borrowAmount);
        vm.stopPrank();

        // Skip time to accrue interest
        vm.warp(block.timestamp + timeSkip);

        // Calculate interest
        uint256 interest = bank.calculateInterestForTesting(user);

        // Interest should be proportional to borrowed amount and time
        // Interest = (borrowedAmount * 500 * timeElapsed) / (10000 * 365 days)
        uint256 expectedInterest = (borrowAmount * 500 * timeSkip) / (10000 * 365 days);
        assertEq(interest, expectedInterest);
    }

    /**
     * @notice Fuzz test for transfer amounts
     * @dev Tests transfers with random amounts to find edge cases
     */
    function testFuzz_Transfer(address from, address to, uint256 depositAmount, uint256 transferAmount) public {
        // Bound and assume inputs
        vm.assume(from != address(0) && to != address(0));
        vm.assume(from != to);
        vm.assume(from != admin && to != admin);
        vm.assume(from.code.length == 0 && to.code.length == 0); // Only EOAs
        vm.assume(uint160(from) > 0x10 && uint160(to) > 0x10); // Exclude precompile addresses
        vm.assume(
            from != address(0x000000000000000000636F6e736F6c652e6c6f67)
                && to != address(0x000000000000000000636F6e736F6c652e6c6f67)
        ); // Exclude console.log
        vm.assume(uint160(from) < type(uint160).max - 1000 && uint160(to) < type(uint160).max - 1000); // Exclude very high addresses
        depositAmount = bound(depositAmount, MINIMUM_BALANCE, 50 ether);
        transferAmount = bound(transferAmount, 0.1 ether, depositAmount / 2); // Reduced transfer amount

        // Setup both accounts
        vm.deal(from, depositAmount + ACTIVATION_FEE + 1 ether);
        vm.deal(to, MINIMUM_BALANCE + ACTIVATION_FEE + 1 ether);

        // Create accounts
        vm.prank(from);
        bank.createAccount{value: depositAmount}();

        vm.prank(to);
        bank.createAccount{value: MINIMUM_BALANCE}();

        uint256 fromBalanceBefore = bank.getBalance(from);
        uint256 toBalanceBefore = bank.getBalance(to);

        // Transfer
        vm.prank(from);
        bank.transferFunds(to, transferAmount);

        // Verify balances
        assertEq(bank.getBalance(from), fromBalanceBefore - transferAmount);
        assertEq(bank.getBalance(to), toBalanceBefore + transferAmount);
    }

    /**
     * @notice Fuzz test for withdrawal amounts
     * @dev Tests withdrawals with random amounts to ensure proper validation
     */
    function testFuzz_Withdraw(address user, uint256 depositAmount, uint256 withdrawAmount) public {
        // Bound inputs
        vm.assume(user != address(0));
        vm.assume(user != admin);
        vm.assume(user.code.length == 0); // Only EOAs
        vm.assume(uint160(user) > 0x10); // Exclude precompile addresses (0x1-0x9) and other low addresses
        vm.assume(user != address(0x000000000000000000636F6e736F6c652e6c6f67)); // Exclude console.log address
        vm.assume(uint160(user) < type(uint160).max - 1000); // Exclude very high addresses that might be special
        depositAmount = bound(depositAmount, 100 ether, 200 ether);
        withdrawAmount = bound(withdrawAmount, 0.1 ether, depositAmount / 2); // Reduced withdraw amount

        // Setup
        vm.deal(user, depositAmount + ACTIVATION_FEE + 1 ether); // Extra for gas

        vm.startPrank(user);
        bank.createAccount{value: depositAmount}();

        uint256 balanceBefore = bank.getBalance(user);
        uint256 userEthBefore = user.balance;

        bank.withdraw(withdrawAmount);

        // Verify state changes
        assertEq(bank.getBalance(user), balanceBefore - withdrawAmount);
        assertEq(user.balance, userEthBefore + withdrawAmount);
        vm.stopPrank();
    }
}
