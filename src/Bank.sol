// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IBankAccount} from "./interfaces/IBankAccount.sol";

/**
 * @title Bank
 * @dev A simple bank contract that allows users to deposit ,withdraw, transfer, borrow funds.
 * @author kavinda rathnayake
 * @notice This contract is for educational purposes only.
 * @notice this contract responsibilities to handle the borrow and payback of funds logics.
 */
contract Bank {

    // state variables -----------------------------------------------------------------------------
    IBankAccount private immutable i_bankAccount; // Immutable variable to store the bank account contract address
    address private immutable i_owner; // Immutable variable to store the owner of the bank contract
    uint256 private constant MAX_BORROW_AMOUNT = 100 ether; // Maximum amount that can be borrowed
    uint256 private constant INTEREST_RATE = 5; // Interest rate for borrowing, represented as a percentage
    // Structs and mappings ------------------------------------------------------------------------
    struct borrower {
        uint256 borrowedAmount;
        uint256 interestRate;
        uint256 borrowAt;
        uint256 dueDate;
    } // Struct to hold borrower details
    mapping(address => borrower) private borrowers; // Mapping to track borrowers and their details

    /**
     * @dev Constructor to initialize the bank account address.
     * @param _bankAccount The address of the bank account contract.
     */
    constructor(address _bankAccount) {
        // Initialize the bank account address
        i_bankAccount = IBankAccount(_bankAccount);
        // Set the owner of the bank contract to the deployer
        i_owner = msg.sender;
    }

    // Public . External functions ----------------------------------------------------------------

    /**
     * @param _amount The amount to deposit.
     * @notice Function to deposit money to the Bank.
     */
    function deposit(uint256 _amount) external {
        i_bankAccount.deposit(_amount);
    }

    /**
     * @param _amount The amount to withdraw.
     * @notice Function to withdraw money from the Bank.
     */
    function withdraw(uint256 _amount) external {
        i_bankAccount.withdraw(_amount);
    }

    /**
     * @param _to The address to transfer funds to.
     * @param _amount The amount to transfer.
     * @notice Function to transfer funds from the Bank.
     */
    function transferFunds(address _to, uint256 _amount) external {
        i_bankAccount.transferFunds(_to, _amount);
    }

    // Internal functions --------------------------------------------------------------------------


    // View functions ------------------------------------------------------------------------------
}