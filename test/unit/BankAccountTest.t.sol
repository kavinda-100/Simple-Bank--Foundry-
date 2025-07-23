// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {BankAccount} from "../../src/BankAccount.sol";

/**
 * @title BankAccountTest
 * @dev Comprehensive tests for BankAccount.sol to achieve 100% test coverage
 * @notice This test suite focuses on edge cases and error conditions to ensure complete coverage
 */
contract BankAccountTest is Test {
    BankAccount public bankAccount;
    address public deployer;
    address public user1 = address(0x123);
    address public user2 = address(0x456);
    address public unauthorizedUser = address(0x789);

    // Mock contract that will reject ETH transfers to simulate transfer failures
    MockRejectETH public mockRejectETH;

    function setUp() public {
        // Deploy BankAccount
        bankAccount = new BankAccount();
        deployer = address(this);

        // Give users some ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(unauthorizedUser, 100 ether);

        // Deploy mock contract that rejects ETH
        mockRejectETH = new MockRejectETH();
        vm.deal(address(mockRejectETH), 100 ether);
    }

    // ================================= Invalid Address Tests =================================

    /**
     * @dev Test createAccount with invalid address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_CreateAccount_InvalidAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.createAccount{value: 1 ether}(address(0));
    }

    /**
     * @dev Test deposit with invalid address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_Deposit_InvalidAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.deposit{value: 1 ether}(address(0));
    }

    /**
     * @dev Test withdraw with invalid address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_Withdraw_InvalidAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.withdraw(address(0), 1 ether);
    }

    /**
     * @dev Test transferFunds with invalid _from address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_TransferFunds_InvalidFromAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.transferFunds(address(0), user1, 1 ether);
    }

    /**
     * @dev Test transferFunds with invalid _to address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_TransferFunds_InvalidToAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.transferFunds(user1, address(0), 1 ether);
    }

    /**
     * @dev Test payLoan with invalid address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_PayLoan_InvalidAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.payLoan(address(0), 1 ether, deployer);
    }

    /**
     * @dev Test receiveLoan with invalid address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_ReceiveLoan_InvalidAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.receiveLoan{value: 1 ether}(address(0), deployer);
    }

    /**
     * @dev Test grantAdminRoleToBank with invalid address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_GrantAdminRoleToBank_InvalidAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.grantAdminRoleToBank(address(0));
    }

    /**
     * @dev Test getBalance with invalid address (address(0))
     * Should trigger BankAccount__InvalidAddress error
     */
    function test_GetBalance_InvalidAddress() public {
        vm.expectRevert(BankAccount.BankAccount__InvalidAddress.selector);
        bankAccount.getBalance(address(0));
    }

    // ================================= Unauthorized Access Tests =================================

    /**
     * @dev Test payLoan without admin role
     * Should trigger BankAccount__UnAuthorized error
     */
    function test_PayLoan_Unauthorized() public {
        // Create an account first
        bankAccount.createAccount{value: 1 ether}(user1);

        vm.prank(unauthorizedUser);
        vm.expectRevert(BankAccount.BankAccount__UnAuthorized.selector);
        bankAccount.payLoan(user1, 0.5 ether, unauthorizedUser);
    }

    /**
     * @dev Test receiveLoan without admin role
     * Should trigger BankAccount__UnAuthorized error
     */
    function test_ReceiveLoan_Unauthorized() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(BankAccount.BankAccount__UnAuthorized.selector);
        bankAccount.receiveLoan{value: 1 ether}(user1, unauthorizedUser);
    }

    /**
     * @dev Test grantAdminRoleToBank without admin role
     * Should trigger BankAccount__UnAuthorized error
     */
    function test_GrantAdminRoleToBank_Unauthorized() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(BankAccount.BankAccount__UnAuthorized.selector);
        bankAccount.grantAdminRoleToBank(user1);
    }

    // ================================= Transfer Failed Tests =================================

    /**
     * @dev Test withdraw when ETH transfer fails
     * Should trigger BankAccount__TransferFailed error
     */
    function test_Withdraw_TransferFailed() public {
        // First create an account for the mock contract that rejects ETH
        bankAccount.createAccount{value: 2 ether}(address(mockRejectETH));

        // Try to withdraw - this should fail because mockRejectETH rejects ETH transfers
        vm.expectRevert(BankAccount.BankAccount__TransferFailed.selector);
        bankAccount.withdraw(address(mockRejectETH), 1 ether);
    }

    // ================================= Getter Function Tests =================================

    /**
     * @dev Test getMinimumBalance function to achieve 100% function coverage
     * This is a simple getter that returns the MINIMUM_BALANCE constant
     */
    function test_GetMinimumBalance() public view {
        uint256 minimumBalance = bankAccount.getMinimumBalance();
        assertEq(minimumBalance, 1 ether, "Minimum balance should be 1 ether");
    }

    /**
     * @dev Test owner function
     */
    function test_Owner() public view {
        address owner = bankAccount.owner();
        assertEq(owner, deployer, "Owner should be the deployer");
    }

    /**
     * @dev Test adminRole function
     */
    function test_AdminRole() public view {
        bytes32 adminRole = bankAccount.adminRole();
        assertEq(adminRole, bankAccount.DEFAULT_ADMIN_ROLE(), "Admin role should be DEFAULT_ADMIN_ROLE");
    }

    // ================================= Additional Edge Case Tests =================================

    /**
     * @dev Test successful payLoan to ensure the success branch is covered
     */
    function test_PayLoan_Success() public {
        // Create account and add some balance to contract
        bankAccount.createAccount{value: 2 ether}(user1);

        // Pay loan should succeed
        bool success = bankAccount.payLoan(user1, 1 ether, deployer);
        assertTrue(success, "PayLoan should succeed");
    }

    /**
     * @dev Test successful receiveLoan
     */
    function test_ReceiveLoan_Success() public {
        // Should succeed and emit event
        vm.expectEmit(true, true, true, true);
        emit BankAccount.LoanReceived(user1, 1 ether);

        bankAccount.receiveLoan{value: 1 ether}(user1, deployer);
    }

    /**
     * @dev Test grantAdminRoleToBank success case
     */
    function test_GrantAdminRoleToBank_Success() public {
        // Grant admin role to user1
        bankAccount.grantAdminRoleToBank(user1);

        // Verify user1 now has admin role
        assertTrue(bankAccount.hasRole(bankAccount.DEFAULT_ADMIN_ROLE(), user1), "User1 should have admin role");
    }
}

/**
 * @dev Mock contract that rejects all ETH transfers
 * Used to test the transfer failure scenario in withdraw function
 */
contract MockRejectETH {
    // This contract will reject all ETH transfers by not having a receive/fallback function
    // or by reverting in them

    receive() external payable {
        revert("ETH transfer rejected");
    }

    fallback() external payable {
        revert("ETH transfer rejected");
    }
}
