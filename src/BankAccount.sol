// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BankAccount
 * @dev A simple contract that represents a bank account with the ability to deposit and withdraw funds.
 * @author kavinda rathnayake
 * @notice This contract is for educational purposes only.
 */
contract BankAccount {
    // Error messages -------------------------------------------------------------------------------------
    error BankAccount__InvalidAddress();
    error BankAccount__DepositAmountMustBeGreaterThanZero();
    error BankAccount__InsufficientBalance();
    error BankAccount__AccountNotActive();
    error BankAccount__AccountAlreadyActive();
    error BankAccount__TransferFailed();

    // State variables -------------------------------------------------------------------------------------
    address private immutable i_deployer; // The address of the deployer
    // Mappings to store account information
    mapping(address owner => uint256 balance) private s_balances; // Mapping to store balances of each account
    mapping(address owner => bool isAccountActive) private s_accounts_active; // Mapping to check if an account is active

    // Events ---------------------------------------------------------------------------------------------
    event Deposit(address indexed owner, uint256 amount); // Event emitted when a deposit is made
    event Withdrawal(address indexed owner, uint256 amount); // Event emitted when a withdrawal is made
    event AccountFrozen(address indexed owner); // Event emitted when an account is frozen
    event AccountActivated(address indexed owner); // Event emitted when an account is activated

    // Constructor -----------------------------------------------------------------------------------------
    constructor(address _deployer) {
        i_deployer = _deployer;
    }

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
     * @notice This modifier checks if the deployer address is calling the function
     * @dev It reverts the transaction if the deployer address is invalid.
     */
    modifier onlyDeployer() {
        // Check if the deployer address is valid
        if(msg.sender != i_deployer) {
            revert BankAccount__InvalidAddress(); // Revert if the deployer is not the contract deployer
        }
        _;
    }

    // Public / External functions ------------------------------------------------------------------------------------

    /**
     * @param _amount The amount to deposit into the account
     * @notice This function allows the caller to deposit funds into their account.
     * @dev It checks if the amount is greater than zero before proceeding with the deposit.
     */
    function deposit(uint256 _amount) external {
        // Call the internal deposit function
        _deposit(msg.sender, _amount);
    }

    /**
     * @param _amount The amount to withdraw from the account
     * @notice This function allows the caller to withdraw funds from their account.
     * @dev It checks if the account is active and if the balance is sufficient before proceeding with the withdrawal.
     */
    function withdraw(uint256 _amount) external {
        // Call the internal withdraw function
        _withdraw(msg.sender, _amount);
    }

    /**
     * @notice This function allows the caller to freeze their account.
     * @dev It sets the account's active status to false, preventing further transactions.
     */
    function freezeAccount() external onlyDeployer {
        // Call the internal freeze account function
        _freezeAccount(msg.sender);
    }

    /**
     * @notice This function allows the caller to activate their account.
     * @dev It sets the account's active status to true, allowing transactions again.
     */
    function activateAccount() external onlyDeployer{
        // Call the internal activate account function
        _activateAccount(msg.sender);
    }


    // Internal functions --------------------------------------------------------------------------------

    function _deposit(address _owner, uint256 _amount) internal isValidAddress(_owner) {
        // Ensure the deposit amount is greater than zero
        if (_amount <= 0) {
            revert BankAccount__DepositAmountMustBeGreaterThanZero();
        }
        // Deposit the amount into the account
        s_balances[_owner] += _amount;
        // Emit a deposit event
        emit Deposit(_owner, _amount);
    }

    function _withdraw(address _owner, uint256 _amount) internal isValidAddress(_owner) {
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
        // Emit a withdrawal event
        emit Withdrawal(_owner, _amount);
    }

    /**
     * @param _owner The address of the account owner to check
     * @return A boolean indicating whether the account is active or not.
     * @dev This function checks if the account is active.
     */
    function _isAccountActive(address _owner) internal isValidAddress(_owner) view returns (bool)  {
        return s_accounts_active[_owner]; // Check if the account is active
    }

    /**
     * @param _owner The address of the account owner to freeze
     * @dev This function freezes the account by setting its active status to false.
     * It can be used to prevent further transactions from the account.
     * @notice This function is internal and should be called with caution. NOTE: Freezing an account will prevent any deposits, withdrawals,  * or transfers. It is typically used for when user not payback their loan on time.
     */
    function _freezeAccount(address _owner) internal isValidAddress(_owner) {
        // Ensure the account is currently active
        if (!_isAccountActive(_owner)) {
            revert BankAccount__AccountNotActive(); // Revert if the account is not active
        }
        // Freeze the account
        s_accounts_active[_owner] = false; // Freeze account
        // Emit an account frozen event
        emit AccountFrozen(_owner); // Emit event indicating account is frozen
    }

    /**
     * @param _owner The address of the account owner to activate
     * @dev This function activates the account by setting its active status to true.
     * It can be used to allow transactions from the account again.
     * @notice This function is internal and should be called with caution.
     */
    function _activateAccount(address _owner) internal isValidAddress(_owner) {
        // Ensure the account is not already active
        if (_isAccountActive(_owner)) {
            revert BankAccount__AccountAlreadyActive(); // Revert if the account is already active
        }
        // Activate the account
        s_accounts_active[_owner] = true; // Activate account
        // Emit an account activated event
        emit AccountActivated(_owner); // Emit event indicating account is activated
    }


    // Getters -------------------------------------------------------------------------------------------------

    /**
     * @param _owner The address of the account owner whose balance is being queried
     * @return The balance of the specified account owner.
     * @notice This function is external and can be called by anyone to check the balance of an account.
     * @dev It returns the balance of the specified account owner.
     */
    function getBalance(address _owner) external view returns (uint256) {
        return s_balances[_owner];
    }


    /**
     * @param _owner The address of the account owner to check
     * @return A boolean indicating whether the account is active or not.
     * @notice This function is external and can be called by anyone to check if an account is active.
     * @dev It returns true if the account is active, false otherwise.
     */
    function isAccountActive(address _owner) external view returns (bool) {
        return _isAccountActive(_owner);
    }

    /**
     * @return The address of the deployer of the contract.
     * @notice This function is external and can be called by anyone to get the deployer's address.
     * @dev It returns the address of the deployer of the contract.
     */
    function getDeployer() external view returns (address) {
        return i_deployer; // Return the deployer's address
    }


}