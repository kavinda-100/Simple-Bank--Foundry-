// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IBankAccount} from "./interfaces/IBankAccount.sol";
import {BankAccount} from "./BankAccount.sol";

/**
 * @title Bank
 * @dev A simple bank contract that allows users to deposit ,withdraw, transfer, borrow funds.
 * @author kavinda rathnayake
 * @notice This contract is for educational purposes only.
 * @notice this contract responsibilities to handle the borrow and payback of funds logics.
 */
contract Bank is AccessControl {
    // Custom Errors --------------------------------------------------------------------------------
    error Bank__InvalidAddress();
    error Bank__NotEligibleToBorrow();
    error Bank__MaxBorrowAmountReached();
    error Bank__AccountNotActive();
    error Bank__DueDatePassed();
    error Bank__TransferFailed();
    error Bank__UnAuthorized();
    error Bank__AccountAlreadyActive();
    error Bank__AmountIsInsufficient();
    error Bank__InsufficientActivationFee(); // Error for insufficient activation fee

    // Events --------------------------------------------------------------------------------------
    event Borrowed(address indexed borrower, uint256 amount, uint256 dueDate); // Event emitted when a user borrows funds
    event PaidBack(address indexed borrower, uint256 amount); // Event emitted when a user pays back borrowed funds
    event AccountFrozen(address indexed owner); // Event emitted when an account is frozen
    event AccountActivated(address indexed owner); // Event emitted when an account is activated

    // state variables -----------------------------------------------------------------------------
    IBankAccount private immutable i_bankAccount; // Immutable variable to store the bank account contract address
    address private immutable i_owner; // Immutable variable to store the owner of the bank contract
    mapping(address owner => bool isAccountActive) private s_accounts_active; // Mapping to check if an account is active
    uint256 private constant MAX_BORROW_AMOUNT = 100 ether; // Maximum amount that can be borrowed
    uint256 private constant INTEREST_RATE = 500; // Interest rate in basis points (500 = 5.00%)
    uint256 private constant BASIS_POINTS = 10000; // 1 basis point = 0.01%
    uint256 private constant SECONDS_IN_YEAR = 365 days; // Seconds in a year for annualized interest
    uint256 private constant ACTIVATION_FEE = 0.05 ether; // Activation fee for accounts
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
        // Grant the deployer the admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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
        if (_user == address(0)) {
            revert Bank__InvalidAddress(); // Revert if the user address is invalid
        }
        _;
    }

    /**
     * @notice This modifier checks if the caller has the admin role
     * @dev It reverts the transaction if the caller doesn't have admin privileges
     */
    modifier onlyAdmin() {
        // Check if the caller has the admin role
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert Bank__UnAuthorized(); // Revert if the caller is not an admin
        }
        _;
    }

    // Public / External functions ----------------------------------------------------------------

    /**
     * @notice Function to create an account in the Bank.
     * @dev User sends ETH and Bank forwards it to BankAccount on behalf of the user.
     */
    function createAccount() external payable {
        // Create an account in the BankAccount contract
        i_bankAccount.createAccount{value: msg.value}(msg.sender);
        // Activate the account after creation
        _activateAccount(msg.sender);
    }

    /**
     * @notice Function to deposit ETH to the Bank.
     * @dev User sends ETH and Bank forwards it to BankAccount on behalf of the user.
     */
    function deposit() external payable {
        i_bankAccount.deposit{value: msg.value}(msg.sender);
    }

    /**
     * @param _amount The amount to withdraw.
     * @notice Function to withdraw ETH from the Bank.
     */
    function withdraw(uint256 _amount) external {
        i_bankAccount.withdraw(msg.sender, _amount);
    }

    /**
     * @param _to The address to transfer funds to.
     * @param _amount The amount to transfer.
     * @notice Function to transfer funds between accounts in the Bank.
     * @dev This only updates balances, no actual ETH is moved.
     */
    function transferFunds(address _to, uint256 _amount) external {
        i_bankAccount.transferFunds(msg.sender, _to, _amount);
    }

    /**
     * @notice This function allows a user to borrow funds from the Bank.
     * @dev It checks if the borrower is eligible to borrow and updates the borrower's details accordingly.
     * The borrower can borrow up to a maximum amount defined by MAX_BORROW_AMOUNT.
     * The interest rate is set to INTEREST_RATE, and the due date is set to 30 days from the borrowing date.
     */
    function borrow(uint256 _amount) external {
        // Call the internal borrow function
        _borrow(msg.sender, _amount);
    }

    /**
     * @notice This function allows a user to pay back borrowed funds.
     * @dev It checks if the borrower has an active account and if the due date has not passed.
     * If the due date has passed, it reverts the transaction.
     */
    function payBack() external payable {
        // Call the internal pay back function
        _payBack(msg.sender, msg.value);
    }

    /**
     * @notice This function allows an admin to freeze an account.
     * @dev It sets the account's active status to false, preventing further transactions.
     * @dev Only addresses with ADMIN_ROLE can call this function.
     */
    function freezeAccount(address _account) external onlyAdmin {
        // Call the internal freeze account function
        _freezeAccount(_account);
    }

    /**
     * @notice This function allows an admin to activate an account.
     * @dev It sets the account's active status to true, allowing transactions again.
     * @dev Users can activate their own accounts by calling this function.
     * @dev and has to pay the activation fee.
     */
    function activateAccount(address _account) external payable {
        // Check if the activation fee is sufficient
        if (msg.value < ACTIVATION_FEE) {
            revert Bank__InsufficientActivationFee(); // Revert if the activation fee is insufficient
        }
        // Call the internal activate account function
        _activateAccount(_account);
    }

    // Internal functions --------------------------------------------------------------------------

    /**
     * @param _user The address of the account owner to check
     * @return A boolean indicating whether the account is active or not.
     * @dev This function checks if the account is active.
     */
    function _isAccountActive(
        address _user
    ) internal view isValidAddress(_user) returns (bool) {
        return s_accounts_active[_user]; // Check if the account is active
    }

    /**
     * @param _user The address of the account owner to freeze
     * @dev This function freezes the account by setting its active status to false.
     * It can be used to prevent further transactions from the account.
     * @notice This function is internal and should be called with caution. NOTE: Freezing an account will prevent any deposits, withdrawals,  * or transfers. It is typically used for when user not payback their loan on time.
     */
    function _freezeAccount(address _user) internal isValidAddress(_user) {
        // Ensure the account is currently active
        if (!_isAccountActive(_user)) {
            revert Bank__AccountNotActive(); // Revert if the account is not active
        }
        // Freeze the account
        s_accounts_active[_user] = false; // Freeze account
        // Emit an account frozen event
        emit AccountFrozen(_user); // Emit event indicating account is frozen
    }

    /**
     * @param _user The address of the account owner to activate
     * @dev This function activates the account by setting its active status to true.
     * It can be used to allow transactions from the account again.
     * @notice This function is internal and should be called with caution.
     */
    function _activateAccount(address _user) internal isValidAddress(_user) {
        // Ensure the account is not already active
        if (_isAccountActive(_user)) {
            revert Bank__AccountAlreadyActive(); // Revert if the account is already active
        }
        // Activate the account
        s_accounts_active[_user] = true; // Activate account
        // Emit an account activated event
        emit AccountActivated(_user); // Emit event indicating account is activated
    }

    /**
     * @dev Internal function to check if the borrower is eligible to borrow.
     * @param _borrower The address of the borrower.
     * @return bool Returns true if the borrower is eligible, false otherwise.
     */
    function _isEligibleToBorrow(
        address _borrower
    ) internal view returns (bool) {
        // Check if the borrower has an active account
        return _isAccountActive(_borrower);
    }

    /**
     * @param _borrower The address of the borrower.
     * @param _amount The amount to check.
     * @return bool Returns true if the maximum borrow amount is reached, false otherwise.
     * @notice Function to check if the borrower has reached the maximum borrow amount.
     * @dev It checks if the borrower's current borrowed amount plus the new amount exceeds the maximum borrow amount.
     */
    function _isMaxBorrowAmountReached(
        address _borrower,
        uint256 _amount
    ) internal view returns (bool) {
        // Check if the borrower has reached the maximum borrow amount
        return
            borrowers[_borrower].borrowedAmount + _amount >= MAX_BORROW_AMOUNT;
    }

    /**
     * @param _borrower The address of the borrower.
     * @return uint256 Returns the calculated interest for the borrower.
     * @notice Function to calculate the interest for a borrower.
     * @dev It calculates the interest based on the borrower's borrowed amount, interest rate, and time elapsed.
     * @dev Uses basis points for precision (10000 basis points = 100%).
     * @dev Interest is calculated as: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
     */
    function _calculateInterest(
        address _borrower
    ) internal view returns (uint256) {
        uint256 principal = borrowers[_borrower].borrowedAmount;
        uint256 interestRate = borrowers[_borrower].interestRate;
        uint256 timeElapsed = block.timestamp - borrowers[_borrower].borrowAt;

        // Handle edge case where no time has passed
        if (timeElapsed == 0 || principal == 0) {
            return 0;
        }

        // Calculate annualized interest with precision
        // Formula: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
        return
            (principal * interestRate * timeElapsed) /
            (BASIS_POINTS * SECONDS_IN_YEAR);
    }

    /**
     * @param _borrower The address of the borrower.
     * @param _amount The amount to borrow.
     * @notice Function to borrow funds from the Bank.
     * @dev It checks if the borrower is eligible to borrow and updates the borrower's details
     * accordingly. The borrower can borrow up to a maximum amount defined by MAX_BORROW_AMOUNT.
     * The interest rate is set to INTEREST_RATE, and the due date is set to 30 days from the
     * borrowing date.
     * @dev It reverts if the borrower is not eligible or if the borrow amount exceeds
     * the maximum borrow amount.
     */
    function _borrow(
        address _borrower,
        uint256 _amount
    ) internal isValidAddress(_borrower) {
        // Check if the borrower is eligible to borrow
        if (!_isEligibleToBorrow(_borrower)) {
            revert Bank__NotEligibleToBorrow(); // Revert if the borrower is not eligible
        }
        // Check if the maximum borrow amount is reached
        if (_isMaxBorrowAmountReached(_borrower, _amount)) {
            revert Bank__MaxBorrowAmountReached(); // Revert if the maximum borrow amount is reached
        }
        // Update the borrower's details
        borrowers[_borrower] = borrower({
            borrowedAmount: borrowers[_borrower].borrowedAmount + _amount,
            interestRate: INTEREST_RATE, // basis points (500 = 5.00%)
            borrowAt: block.timestamp,
            dueDate: block.timestamp + 30 days
        });
        // Transfer the borrowed amount to the borrower
        // i_bankAccount.transferFunds(address(i_bankAccount), _borrower, _amount);
        bool success = i_bankAccount.payLoan(_borrower, _amount, address(this));
        // Check if the transfer was successful
        if (!success) {
            revert Bank__TransferFailed(); // Revert if the transfer fails
        }
        // Emit an event for borrowing
        emit Borrowed(_borrower, _amount, borrowers[_borrower].dueDate);
    }

    /**
     * @param _borrower The address of the borrower.
     * @return uint256 Returns the total amount that has to be paid back (principal + interest).
     * @notice Function to get how much has to be paid back by the borrower.
     * @dev It calculates the total amount to be paid back, including the principal and interest.
     */
    function getHowMuchHasToBePaid(
        address _borrower
    ) external view returns (uint256) {
        // Calculate the total amount to be paid (principal + interest)
        uint256 totalAmount = borrowers[_borrower].borrowedAmount +
            _calculateInterest(_borrower);
        return totalAmount;
    }

    /**
     * @param _borrower The address of the borrower.
     * @notice Function to pay back borrowed funds to the Bank.
     * @dev It checks if the borrower has an active account and if the due date has not passed.
     * If the due date has passed, it reverts the transaction.
     */
    function _payBack(
        address _borrower,
        uint256 _amount
    ) internal isValidAddress(_borrower) {
        // Check if the borrower has an active account
        if (!_isAccountActive(_borrower)) {
            revert Bank__AccountNotActive(); // Revert if the account is not active
        }
        // Check if the due date has passed
        if (block.timestamp > borrowers[_borrower].dueDate) {
            revert Bank__DueDatePassed(); // Revert if the due date has passed
        }
        // Calculate the total amount to pay back (principal + interest)
        uint256 totalAmount = borrowers[_borrower].borrowedAmount +
            _calculateInterest(_borrower);
        // Check if the amount to pay back is not equal to the total amount
        if (_amount != totalAmount) {
            revert Bank__AmountIsInsufficient(); // Revert if the amount to pay back is less than the total amount
        }
        // Transfer the total amount back to the bank
        i_bankAccount.receiveLoan{value: _amount}(_borrower, address(this));
        // Update the borrower's details
        borrowers[_borrower].borrowedAmount = 0;
        borrowers[_borrower].interestRate = 0;
        borrowers[_borrower].dueDate = 0;
        borrowers[_borrower].borrowAt = 0;
        // Emit an event for paying back
        emit PaidBack(_borrower, totalAmount);
    }

    // View functions ------------------------------------------------------------------------------

    /**
     * @param _user The address of the account owner to get the balance of
     * @return The balance of the owner in the bank account.
     * @notice This function is external and can be called by anyone to get the balance of an account.
     * @dev It calls the bank account contract to get the balance of the owner.
     */
    function getBalance(address _user) external view returns (uint256) {
        // Call the bank account contract to get the balance of the user
        return i_bankAccount.getBalance(_user);
    }

    /**
     * @return The owner of the bank contract.
     * @notice This function is external and can be called by anyone to get the owner of the bank contract.
     * @dev It returns the address of the owner of the bank contract.
     */
    function owner() external view returns (address) {
        return i_owner; // Return the owner of the bank contract
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
     * @param _user The address of the account owner to check
     * @return A boolean indicating whether the account is active or not.
     * @notice This function is external and can be called by anyone to check if an account is active.
     * @dev It returns true if the account is active, false otherwise.
     */
    function isAccountActive(address _user) external view returns (bool) {
        return _isAccountActive(_user);
    }

    /**
     * @param _borrower The address of the borrower to get details for
     * @return borrower Returns the borrower's details as a struct.
     * @notice Function to get the borrower's details.
     * @dev Returns the borrower's details including borrowed amount, interest rate, borrow time, and due date.
     */
    function getBorrowerDetails(
        address _borrower
    ) external view returns (borrower memory) {
        // Return the borrower's details
        return borrowers[_borrower];
    }

    /**
     * @param _borrower The address of the borrower to get details for
     * @return borrowedAmount The total amount borrowed by the borrower
     * @return interestRate The interest rate applied to the loan
     * @return borrowAt The timestamp when the loan was taken
     * @return dueDate The due date for loan repayment
     * @notice Function to get the borrower's details as individual values
     * @dev Returns individual values from the borrower struct for easier destructuring
     */
    function getBorrowerDetailsValues(
        address _borrower
    )
        external
        view
        returns (
            uint256 borrowedAmount,
            uint256 interestRate,
            uint256 borrowAt,
            uint256 dueDate
        )
    {
        borrower memory borrowerInfo = borrowers[_borrower];
        return (
            borrowerInfo.borrowedAmount,
            borrowerInfo.interestRate,
            borrowerInfo.borrowAt,
            borrowerInfo.dueDate
        );
    }

    /**
     * @param _borrower The address of the borrower
     * @return uint256 The calculated interest for the borrower
     * @notice Public wrapper function to test the internal _calculateInterest function
     * @dev This function is only meant for testing purposes to access the internal _calculateInterest function
     */
    function calculateInterestForTesting(
        address _borrower
    ) external view returns (uint256) {
        return _calculateInterest(_borrower);
    }

    // Fallback/Receive functions to handle ETH transfers
    receive() external payable {
        // Bank can receive ETH to forward to BankAccount
        i_bankAccount.deposit{value: msg.value}(msg.sender);
    }
}
