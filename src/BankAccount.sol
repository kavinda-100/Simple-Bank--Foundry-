// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BankAccount
 * @dev A simple contract that represents a bank account with the ability to deposit and withdraw funds.
 * @author kavinda rathnayake
 * @notice This contract is for educational purposes only.
 */
contract BankAccount {

    // State variables
    mapping(address owner => uint256 balance) private s_balances; // Mapping to store balances of each account
    mapping(address owner => bool isAccountActive) private s_accounts_active; // Mapping to check if an account is active

    constructor() {
        
    }


    // Internal functions --------------------------------------------------------------------------------

    function _deposit(address owner, uint256 amount) internal {
        require(amount > 0, "Deposit amount must be greater than zero");
        s_balances[owner] += amount;
        s_accounts_active[owner] = true; // Activate account on first deposit
    }

    function _withdraw(address owner, uint256 amount) internal {
        require(s_accounts_active[owner], "Account is not active");
        require(s_balances[owner] >= amount, "Insufficient balance");
        s_balances[owner] -= amount;
        if (s_balances[owner] == 0) {
            s_accounts_active[owner] = false; // Deactivate account if balance is zero
        }
    }

    /**
     * @param owner The address of the account owner to freeze
     * @dev This function freezes the account by setting its active status to false.
     * It can be used to prevent further transactions from the account.
     * @notice This function is internal and should be called with caution.
     */
    function _freezeAccount(address owner) internal {
        s_accounts_active[owner] = false; // Freeze account
    }


    // Getters -------------------------------------------------------------------------------------------------

    /**
     * @param owner The address of the account owner whose balance is being queried
     * @return The balance of the specified account owner.
     * @notice This function is external and can be called by anyone to check the balance of an account.
     * @dev It returns the balance of the specified account owner.
     */
    function getBalance(address owner) external view returns (uint256) {
        return s_balances[owner];
    }
    

    /**
     * @param owner The address of the account owner to check
     * @return A boolean indicating whether the account is active or not.
     * @notice This function is external and can be called by anyone to check if an account is active.
     * @dev It returns true if the account is active, false otherwise.
     */
    function isAccountActive(address owner) external view returns (bool) {
        return s_accounts_active[owner];
    }


}