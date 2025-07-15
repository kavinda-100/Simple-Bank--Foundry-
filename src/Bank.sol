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
    IBankAccount private immutable i_bankAccount;

    /**
     * @dev Constructor to initialize the bank account address.
     * @param _bankAccount The address of the bank account contract.
     */
    constructor(address _bankAccount) {
        // Initialize the bank account address
        i_bankAccount = IBankAccount(_bankAccount);
    }
}