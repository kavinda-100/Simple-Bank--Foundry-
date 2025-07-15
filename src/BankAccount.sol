// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BankAccount
 * @dev A simple contract that represents a bank account with the ability to deposit and withdraw funds.
 * @author kavinda rathnayake
 * @notice This contract is for educational purposes only.
 */
contract BankAccount {
    // Error messages
    error BankAccount__InvalidAddress();
    error BankAccount__DepositAmountMustBeGreaterThanZero();
    error BankAccount__InsufficientBalance();
    error BankAccount__AccountNotActive();
    error BankAccount__AccountAlreadyActive();
    error BankAccount__TransferFailed();

    // State variables
    mapping(address owner => uint256 balance) private s_balances; // Mapping to store balances of each account
    mapping(address owner => bool isAccountActive) private s_accounts_active; // Mapping to check if an account is active

    constructor() {
        
    }


    // Internal functions --------------------------------------------------------------------------------

    function _deposit(address _owner, uint256 _amount) internal {
        // check if _owner address is valid
        if(_owner == address(0)) {
            revert BankAccount__InvalidAddress(); // Revert if the owner is the zero address
        }
        // Ensure the deposit amount is greater than zero
        if (_amount <= 0) {
            revert BankAccount__DepositAmountMustBeGreaterThanZero();
        }
        // Deposit the amount into the account
        s_balances[_owner] += _amount;
    }

    function _withdraw(address _owner, uint256 _amount) internal {
        // Check if _owner address is valid
        if(_owner == address(0)) {
            revert BankAccount__InvalidAddress(); // Revert if the owner is the zero address
        }
        // Ensure the account is active
        if (!_isAccountActive(_owner)) {
            revert BankAccount__AccountNotActive(); // Revert if the account is not active
        }
        // Ensure the withdrawal amount does not exceed the balance
        if (s_balances[_owner] < _amount) {
            revert BankAccount__InsufficientBalance(); // Revert if insufficient balance
        }
        // Withdraw the amount from the account
        s_balances[_owner] -= _amount;
        // transfer the amount to the owner
        (bool success, ) = payable(_owner).call{value: _amount}("");
        // Check if the transfer was successful
        if (!success) {
            revert BankAccount__TransferFailed(); // Revert if the transfer fails
        }

    }

    /**
     * @param owner The address of the account owner to check
     * @return A boolean indicating whether the account is active or not.
     * @dev This function checks if the account is active.
     */
    function _isAccountActive(address owner) internal view returns (bool) {
        if(owner == address(0)) {
            revert BankAccount__InvalidAddress(); // Revert if the owner is the zero address
        }
        return s_accounts_active[owner]; // Check if the account is active
    }

    /**
     * @param owner The address of the account owner to freeze
     * @dev This function freezes the account by setting its active status to false.
     * It can be used to prevent further transactions from the account.
     * @notice This function is internal and should be called with caution. NOTE: Freezing an account will prevent any deposits, withdrawals,  * or transfers. It is typically used for when user not payback their loan on time.
     */
    function _freezeAccount(address owner) internal {
        // Check if the owner address is valid
        if(owner == address(0)) {
            revert BankAccount__InvalidAddress(); // Revert if the owner is the zero address
        }
        // Ensure the account is currently active
        if (!_isAccountActive(owner)) {
            revert BankAccount__AccountNotActive(); // Revert if the account is not active
        }
        // Freeze the account
        s_accounts_active[owner] = false; // Freeze account
    }

    /**
     * @param owner The address of the account owner to activate
     * @dev This function activates the account by setting its active status to true.
     * It can be used to allow transactions from the account again.
     * @notice This function is internal and should be called with caution.
     */
    function _activateAccount(address owner) internal {
        // Check if the owner address is valid
        if(owner == address(0)) {
            revert BankAccount__InvalidAddress(); // Revert if the owner is the zero address
        }
        // Ensure the account is not already active
        if (_isAccountActive(owner)) {
            revert BankAccount__AccountAlreadyActive(); // Revert if the account is already active
        }
        // Activate the account
        s_accounts_active[owner] = true; // Activate account
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
        return _isAccountActive(owner);
    }


}