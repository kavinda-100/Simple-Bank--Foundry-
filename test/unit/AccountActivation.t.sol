// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";
import {BankAccount} from "../../src/BankAccount.sol";

// import deployment scripts
import {DeployBankSystem} from "../../script/DeployBankSystem.s.sol";

contract AccountActivationTest is Test {
    // Contracts to test
    Bank public bank;
    BankAccount public bankAccount;
    address public deployer;

    // Addresses for test users
    address public user1 = address(0x123);
    address public user2 = address(0x456);

    // constants
    uint256 constant USER_INITIAL_BALANCE = 300 ether;
    uint256 constant USER_DEPOSIT_AMOUNT = 200 ether;

    // Events --------------------------------------------------------------------------------------
    event AccountFrozen(address indexed owner); // Event emitted when an account is frozen
    event AccountActivated(address indexed owner); // Event emitted when an account is activated

    function setUp() public {
        // Deploy complete Bank system using deployment script
        DeployBankSystem deployBankSystemScript = new DeployBankSystem();
        (bankAccount, bank, deployer) = deployBankSystemScript.run();

        // Give test users some ETH to work with
        vm.deal(user1, USER_INITIAL_BALANCE);
        vm.deal(user2, USER_INITIAL_BALANCE);
    }

    // ================================= Modifiers =========================================

    /**
     * @dev Modifier to create an account for a user with a predefined deposit amount.
     * It can be used in test functions to ensure the user has an account before performing actions.
     */
    modifier createAnAccount(address _user) {
        vm.startPrank(_user);
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();
        vm.stopPrank();
        _;
    }

    // ================================= Test Account Activation =========================================

    /**
     * @dev Test to make sure a user can create an account and account is active after creation.
     */
    function test_CreateAccountActivates() public createAnAccount(user1) {
        vm.startPrank(user1);
        // Check if the account is active after creation
        assertTrue(bank.isAccountActive(user1), "Account should be active after creation");
    }

    /**
     * @dev Test to verify that a when user activates their account, it emits the AccountActivated event.
     */
    function test_AccountActivatedEventEmitted() public {
        vm.startPrank(user1);
        // expect the AccountActivated event to be emitted when activating the account
        vm.expectEmit(true, true, true, true);
        emit AccountActivated(user1);
        // create an account to ensure it is active
        bank.createAccount{value: USER_DEPOSIT_AMOUNT}();
        // check if the account is active
        assertTrue(bank.isAccountActive(user1), "Account should still be active");
        vm.stopPrank();
    }

    /**
     *
     * @dev Test to verify that if account already active, it reverts with Bank__AccountAlreadyActive
     */
    function test_AccountAlreadyActiveRevert() public createAnAccount(user1) {
        vm.startPrank(user1);
        // get the activation fee
        uint256 activationFee = bank.getActivationFee();
        // expect revert if trying to activate an already active account
        vm.expectRevert(Bank.Bank__AccountAlreadyActive.selector);
        // Attempt to activate the account again
        bank.activateAccount{value: activationFee}(user1);
        // Check that the account is still active
        assertTrue(bank.isAccountActive(user1), "Account should still be active");
        vm.stopPrank();
    }

    /**
     * @dev Test to verify that when activating an account, if the user does not send enough ETH,
     * it reverts with Bank__InsufficientActivationFee.
     */
    function test_InsufficientActivationFeeRevert() public createAnAccount(user1) {
        // Get the actual owner/admin of the Bank contract
        address bankOwner = bank.owner();

        vm.startPrank(bankOwner);
        bank.freezeAccount(user1); // Freeze the account first
        vm.stopPrank();

        // Verify account is frozen
        assertFalse(bank.isAccountActive(user1), "Account should be frozen");

        vm.startPrank(user1);
        uint256 activationFee = bank.getActivationFee();
        vm.expectRevert(Bank.Bank__InsufficientActivationFee.selector);
        bank.activateAccount{value: activationFee - 1}(user1);
        // Check that the account is still deactivated
        assertFalse(bank.isAccountActive(user1), "Account should not be active due to insufficient fee");
        vm.stopPrank();
    }
}
