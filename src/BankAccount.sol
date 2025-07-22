// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title BankAccount
 * @dev A simple contract that represents a bank account with the ability to deposit and withdraw funds.
 * @author kavinda rathnayake
 * @notice This contract is for educational purposes only.
 * @notice this contract responsibilities to handle the deposit, withdrawal, transfer, getBalance, freeze, and activate account logics.
 */
contract BankAccount is AccessControl {
    // Error messages -------------------------------------------------------------------------------------
    error BankAccount__InvalidAddress();
    error BankAccount__DepositAmountMustBeGreaterThanZero();
    error BankAccount__InsufficientBalance();
    error BankAccount__TransferFailed();
    error BankAccount__LoanAmountMustBeGreaterThanZero();
    error BankAccount__UnAuthorized();
    error BankAccount__BorrowerDoesNotExist();
    error BankAccount__AccountAlreadyExists();
    error BankAccount__DepositAmountMustBeGreaterThanMinimumAmount();
    

    // State variables -------------------------------------------------------------------------------------
    // constants
    uint256 private constant MINIMUM_BALANCE = 1 ether; // Minimum balance required for an account
    address private immutable i_owner; // Immutable variable to store the owner of the bankAccount contract
    // Mappings to store account information
    mapping(address owner => uint256 balance) private s_balances; // Mapping to store balances of each account

    /**
     * @dev Constructor to set up initial roles
     */
    constructor() {
        // Set the owner of the bankAccount contract to the deployer
        i_owner = msg.sender;
        // Grant the deployer the default admin role: it will be able to grant and revoke any roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Events ---------------------------------------------------------------------------------------------
    event Deposit(address indexed owner, uint256 amount); // Event emitted when a deposit is made
    event Withdrawal(address indexed owner, uint256 amount); // Event emitted when a withdrawal is made
    event Transfer(address indexed from, address indexed to, uint256 amount); // Event emitted when funds are transferred
    event LoanPaid(address indexed borrower, uint256 amount); // Event emitted when a loan is paid
    event LoanReceived(address indexed borrower, uint256 amount); // Event emitted when a loan is received
    event CreateAnAccount(address indexed owner, uint256 amount); // Event emitted when an account is created

    // Modifiers -----------------------------------------------------------------------------------------

    /**
     * @param _user The address of the user to check
     * @notice This modifier checks if the user address is valid (not the zero address).
     * @dev It reverts the transaction if the user address is invalid.
     * @dev This modifier is used to ensure that the user address is valid before performing any operations on it.
     */
    modifier isValidAddress(address _user) {
        // Check if the user address is valid
        if(_user == address(0)) {
            revert BankAccount__InvalidAddress(); // Revert if the user is the zero address
        }
        _;
    }

    /**
     * @notice This modifier checks if the caller has the admin role
     * @dev It reverts the transaction if the caller doesn't have admin privileges
     */
    modifier onlyAdmin(address _admin) {
        // Check if the caller has the admin role
        if(!hasRole(DEFAULT_ADMIN_ROLE, _admin)) {
            revert BankAccount__UnAuthorized(); // Revert if the caller is not an admin
        }
        _;
    }

    // Public / External functions ------------------------------------------------------------------------------------

    /**
     * @param _user The address of the user to create an account for
     * @notice This function allows the caller to create an account and deposit funds into it.
     * @dev It checks if the amount is greater than MINIMUM_BALANCE before proceeding with the creation of the account.
     */
    function createAccount(address _user) external payable {
        // Call the internal create account function
        _createAccount(_user, msg.value);
    }

    /**
     * @notice This function allows the caller to deposit ETH into their account.
     * @dev User must send ETH equal to _amount parameter. It checks if the amount is greater than zero before proceeding with the deposit.
     */
    function deposit(address _user) external payable {
        // Call the internal deposit function
        _deposit(_user, msg.value);
    }

    /**
     * @param _amount The amount to withdraw from the account
     * @notice This function allows the caller to withdraw funds from their account.
     * @dev It checks if the account is active and if the balance is sufficient before proceeding with the withdrawal.
     */
    function withdraw(address _user,uint256 _amount) external {
        // Call the internal withdraw function
        _withdraw(_user, _amount);
    }

    /**
     * @param _to The address of the account to transfer funds to
     * @param _amount The amount to transfer between accounts
     * @notice This function allows the caller to transfer funds from their account to another account.
     * @dev It checks if both accounts are active and if the balance is sufficient before proceeding with the transfer.
     */
    function transferFunds(address _from, address _to, uint256 _amount) external {
        // Call the internal transfer funds function
        _transferFunds(_from, _to, _amount);
    }

    /**
     * @param _borrower The address of the borrower to pay the loan
     * @param _amount The amount to pay towards the loan
     * @notice This function allows the caller to pay a loan for a borrower.
     * @dev It checks if the amount is greater than zero and if the contract has sufficient balance before proceeding with the payment.
     */
    function payLoan(address _borrower, uint256 _amount, address _admin) external  isValidAddress(_borrower) onlyAdmin(_admin) returns (bool) {
        // Ensure the amount is greater than zero
        if (_amount <= 0) {
            revert BankAccount__LoanAmountMustBeGreaterThanZero(); // Revert if the amount is zero or negative
        }
        // Ensure the contract has sufficient balance
        if(address(this).balance < _amount) {
            revert BankAccount__InsufficientBalance(); // Revert if the contract has insufficient balance
        }
        // check if the borrower has an account
        if(s_balances[_borrower] == 0) {
            revert BankAccount__BorrowerDoesNotExist(); // Revert if the borrower does not exist
        }
        // Withdraw the amount from the borrower's account
        (bool success, ) = payable(_borrower).call{value: _amount}("");
        // success is checked by Bank contract
        // emit an event indicating the loan payment
        emit LoanPaid(_borrower, _amount);
        return success;
    }

    function receiveLoan(address _borrower, address _admin) external payable isValidAddress(_borrower) onlyAdmin(_admin) {
        // check if the borrower has an account
        if(s_balances[_borrower] == 0) {
            revert BankAccount__BorrowerDoesNotExist(); // Revert if the borrower does not exist
        }
        // Emit an event indicating the loan reception
        emit LoanReceived(_borrower, msg.value);
    }

    /**
     * @param _bankAddress The address of the Bank contract to grant admin role to
     * @notice This function allows the current admin to grant admin role to the Bank contract.
     * @dev Only the current admin can call this function.
     */
    function grantAdminRoleToBank(address _bankAddress) external isValidAddress(_bankAddress) onlyAdmin(msg.sender) {
        // Grant admin role to the Bank contract
        _grantRole(DEFAULT_ADMIN_ROLE, _bankAddress);
    }


    // Internal functions --------------------------------------------------------------------------------

    /**
     * @param _user The address of the account owner to deposit funds into creating the account
     * @param _amount The amount to deposit into the account
     * @notice This function creates an account for the user if it does not exist and deposits funds into it.
     * @dev It checks if the amount is greater than MINIMUM_BALANCE before proceeding with the deposit.
     */
    function _createAccount(address _user, uint256 _amount) internal isValidAddress(_user) {
        // Check if the account already exists
        if (s_balances[_user] > 0) {
            revert BankAccount__AccountAlreadyExists(); // Revert if the account already exists
        }
        // Ensure the deposit amount is greater than the minimum balance
        if (_amount < MINIMUM_BALANCE) {
            revert BankAccount__DepositAmountMustBeGreaterThanMinimumAmount(); // Revert if the amount is less than the minimum balance
        }
        // Initialize the account with the specified amount
        s_balances[_user] = _amount;
        // Emit a create account event
        emit CreateAnAccount(_user, _amount);
    }

    /**
     * @param _user The address of the account owner to deposit funds into
     * @param _amount The amount to deposit into the account
     * @dev This function deposits funds into the specified account.
     * It checks if the amount is greater than zero before proceeding with the deposit.
     */
    function _deposit(address _user, uint256 _amount) internal isValidAddress(_user) {
        // Ensure the deposit amount is greater than zero
        if (_amount <= 0) {
            revert BankAccount__DepositAmountMustBeGreaterThanZero();
        }
        // Deposit the amount into the account
        s_balances[_user] += _amount;
        // Emit a deposit event
        emit Deposit(_user, _amount);
    }

    /**
     * @param _user The address of the account owner to withdraw funds from
     * @param _amount The amount to withdraw from the account
     * @dev This function withdraws funds from the specified account.
     * It checks if the account is active and if the balance is sufficient before proceeding with the withdrawal.
     */
    function _withdraw(address _user, uint256 _amount) internal isValidAddress(_user) {
        // Ensure the withdrawal amount does not exceed the balance
        if (s_balances[_user] < _amount) {
            revert BankAccount__InsufficientBalance(); // Revert if insufficient balance
        }
        // Withdraw the amount from the account
        s_balances[_user] -= _amount;
        // transfer the amount to the owner
        (bool success, ) = payable(_user).call{value: _amount}("");
        // Check if the transfer was successful
        if (!success) {
            revert BankAccount__TransferFailed(); // Revert if the transfer fails
        }
        // Emit a withdrawal event
        emit Withdrawal(_user, _amount);
    }

    /**
     * @param _from The address of the account owner to transfer funds from
     * @param _to The address of the account owner to transfer funds to
     * @param _amount The amount to transfer between accounts
     * @dev This function transfers funds from one account to another.
     * It checks if both accounts are active and if the balance is sufficient before proceeding with the transfer.
     */
    function _transferFunds(address _from, address _to, uint256 _amount) internal isValidAddress(_from) isValidAddress(_to) {
        // Ensure the withdrawal amount does not exceed the balance
        if (s_balances[_from] < _amount) {
            revert BankAccount__InsufficientBalance(); // Revert if insufficient balance
        }
        // Withdraw the amount from the sender's account
        s_balances[_from] -= _amount;
        // Deposit the amount into the recipient's account
        s_balances[_to] += _amount;
        // Emit a transfer event
        emit Transfer(_from, _to, _amount); // Emit event indicating funds were transferred
    }


    // Getters -------------------------------------------------------------------------------------------------

    /**
     * @param _user The address of the account owner whose balance is being queried
     * @return The balance of the specified account owner.
     * @notice This function is external and can be called by anyone to check the balance of an account.
     * @dev It returns the balance of the specified account owner.
     */
    function getBalance(address _user) external isValidAddress(_user) view returns (uint256) {
        return s_balances[_user];
    }


    /**
     * @return The owner of the bankAccount contract.
     * @notice This function is external and can be called by anyone to get the owner of the bankAccount contract.
     * @dev It returns the address of the owner of the bankAccount contract.
     */
    function owner() external view returns (address) {
        return i_owner; // Return the owner of the bankAccount contract
    }

    /**
     * @return The admin role identifier.
     * @notice This function is external and can be called by anyone to get the admin role identifier.
     * @dev It returns the DEFAULT_ADMIN_ROLE constant from AccessControl.
     */
    function adminRole() external pure returns (bytes32) {
        return DEFAULT_ADMIN_ROLE; // Return the admin role identifier
    }

    /**
     * @return The minimum balance required to create an account.
     * @notice This function is external and can be called by anyone to get the minimum balance required to create an account.
     * @dev It returns the constant MINIMUM_BALANCE defined in the contract.
     */
    function getMinimumBalance() external pure returns (uint256) {
        return MINIMUM_BALANCE; // Return the minimum balance required to create an account
    }

}