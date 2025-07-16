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

    // Events --------------------------------------------------------------------------------------
    event Borrowed(address indexed borrower, uint256 amount, uint256 dueDate); // Event emitted when a user borrows funds
    event PaidBack(address indexed borrower, uint256 amount); // Event emitted when a user pays back borrowed funds

    // state variables -----------------------------------------------------------------------------
    IBankAccount private immutable i_bankAccount; // Immutable variable to store the bank account contract address
    address private immutable i_owner; // Immutable variable to store the owner of the bank contract
    uint256 private constant MAX_BORROW_AMOUNT = 100 ether; // Maximum amount that can be borrowed
    uint256 private constant INTEREST_RATE = 500; // Interest rate in basis points (500 = 5.00%)
    uint256 private constant BASIS_POINTS = 10000; // 1 basis point = 0.01%
    uint256 private constant SECONDS_IN_YEAR = 365 days; // Seconds in a year for annualized interest
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
        if(_user == address(0)) {
            revert Bank__InvalidAddress(); // Revert if the user address is invalid
        }
        _;
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

    /**
     * @dev Internal function to check if the borrower is eligible to borrow.
     * @param _borrower The address of the borrower.
     * @return bool Returns true if the borrower is eligible, false otherwise.
     */
    function _isEligibleToBorrow(address _borrower) internal view returns (bool) {
        // Check if the borrower has an active account and has not borrowed more than the maximum borrow amount
        return i_bankAccount.isAccountActive(_borrower) && borrowers[_borrower].borrowedAmount <= MAX_BORROW_AMOUNT;
    }

    /**
     * @param _borrower The address of the borrower.
     * @param _amount The amount to check.
     * @return bool Returns true if the maximum borrow amount is reached, false otherwise.
     * @notice Function to check if the borrower has reached the maximum borrow amount.
     * @dev It checks if the borrower's current borrowed amount plus the new amount exceeds the maximum borrow amount.
     */
    function _isMaxBorrowAmountReached(address _borrower, uint256 _amount) internal view returns (bool) {
        // Check if the borrower has reached the maximum borrow amount
        return borrowers[_borrower].borrowedAmount + _amount >= MAX_BORROW_AMOUNT;
    }

    /**
     * @param _borrower The address of the borrower.
     * @return uint256 Returns the calculated interest for the borrower.
     * @notice Function to calculate the interest for a borrower.
     * @dev It calculates the interest based on the borrower's borrowed amount, interest rate, and time elapsed.
     * @dev Uses basis points for precision (10000 basis points = 100%).
     * @dev Interest is calculated as: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
     */
    function _calculateInterest(address _borrower) internal view returns (uint256) {
        uint256 principal = borrowers[_borrower].borrowedAmount;
        uint256 interestRate = borrowers[_borrower].interestRate;
        uint256 timeElapsed = block.timestamp - borrowers[_borrower].borrowAt;
        
        // Handle edge case where no time has passed
        if (timeElapsed == 0 || principal == 0) {
            return 0;
        }
        
        // Calculate annualized interest with precision
        // Formula: (principal * rate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR)
        return (principal * interestRate * timeElapsed) / (BASIS_POINTS * SECONDS_IN_YEAR);
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
    function _borrow(address _borrower, uint256 _amount) internal isValidAddress(_borrower) {
        // Check if the borrower is eligible to borrow
        if(!_isEligibleToBorrow(_borrower)) {
            revert Bank__NotEligibleToBorrow(); // Revert if the borrower is not eligible
        }
        // Check if the maximum borrow amount is reached
        if(_isMaxBorrowAmountReached(_borrower, _amount)) {
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
        i_bankAccount.transferFunds(_borrower, _amount);
        // Emit an event for borrowing
        emit Borrowed(_borrower, _amount, borrowers[_borrower].dueDate);
    }

    /**
     * @param _borrower The address of the borrower.
     * @notice Function to pay back borrowed funds to the Bank.
     * @dev It checks if the borrower has an active account and if the due date has not passed.
     * If the due date has passed, it reverts the transaction.
     */
    function _payBack(address _borrower) internal isValidAddress(_borrower) {
        // Check if the borrower has an active account
        if(!i_bankAccount.isAccountActive(_borrower)) {
            revert Bank__AccountNotActive(); // Revert if the account is not active
        }
        // Check if the due date has passed
        if(block.timestamp > borrowers[_borrower].dueDate) {
            revert Bank__DueDatePassed(); // Revert if the due date has passed
        }
        // Calculate the total amount to pay back (principal + interest)
        uint256 totalAmount = borrowers[_borrower].borrowedAmount + _calculateInterest(_borrower);
        // Transfer the total amount back to the bank
        i_bankAccount.transferFunds(address(this), totalAmount);
        // Update the borrower's details
        borrowers[_borrower].borrowedAmount = 0;
        borrowers[_borrower].interestRate = 0;
        borrowers[_borrower].dueDate = 0;
        // Emit an event for paying back
        emit PaidBack(_borrower, totalAmount);
    }

    /**
     * @param _borrower The address of the borrower to freeze.
     * @notice Function to freeze a borrower's account (admin only).
     * @dev This function can be called when a borrower fails to pay back on time.
     * @dev Only addresses with DEFAULT_ADMIN_ROLE can call this function.
     */
    function freezeBorrowerAccount(address _borrower) external onlyRole(DEFAULT_ADMIN_ROLE) isValidAddress(_borrower) {
        // Check if the borrower has an outstanding loan
        require(borrowers[_borrower].borrowedAmount > 0, "Bank: No outstanding loan");
        
        // Check if the due date has passed
        require(block.timestamp > borrowers[_borrower].dueDate, "Bank: Due date not yet passed");
        
        // Freeze the account in BankAccount contract
        i_bankAccount.freezeAccount(_borrower);
    }

    /**
     * @param _borrower The address of the borrower to activate.
     * @notice Function to activate a borrower's account (admin only).
     * @dev This function can be called after a borrower has resolved their debt.
     * @dev Only addresses with DEFAULT_ADMIN_ROLE can call this function.
     */
    function activateBorrowerAccount(address _borrower) external onlyRole(DEFAULT_ADMIN_ROLE) isValidAddress(_borrower) {
        // Activate the account in BankAccount contract
        i_bankAccount.activateAccount(_borrower);
    }


    // View functions ------------------------------------------------------------------------------
    
    /**
     * @param _borrower The address of the borrower.
     * @return borrowedAmount The amount borrowed by the borrower.
     * @return interestRate The interest rate in basis points (10000 = 100%).
     * @return borrowAt The timestamp when the loan was taken.
     * @return dueDate The due date for loan repayment.
     * @return currentInterest The current accrued interest.
     * @return totalAmountDue The total amount due (principal + interest).
     * @notice Function to get comprehensive borrower information.
     */
    function getBorrowerInfo(address _borrower) 
        external 
        view 
        returns (
            uint256 borrowedAmount,
            uint256 interestRate,
            uint256 borrowAt,
            uint256 dueDate,
            uint256 currentInterest,
            uint256 totalAmountDue
        ) 
    {
        borrower memory borrowerInfo = borrowers[_borrower];
        currentInterest = _calculateInterest(_borrower);
        
        return (
            borrowerInfo.borrowedAmount,
            borrowerInfo.interestRate,
            borrowerInfo.borrowAt,
            borrowerInfo.dueDate,
            currentInterest,
            borrowerInfo.borrowedAmount + currentInterest
        );
    }

    /**
     * @param _borrower The address of the borrower.
     * @param _timeElapsed Optional time elapsed in seconds. If 0, uses current time.
     * @return interest The calculated interest for the given time period.
     * @notice Function to preview interest calculation for a borrower.
     * @dev Useful for front-end applications to show users expected interest.
     */
    function previewInterest(address _borrower, uint256 _timeElapsed) 
        external 
        view 
        returns (uint256 interest) 
    {
        uint256 principal = borrowers[_borrower].borrowedAmount;
        uint256 interestRate = borrowers[_borrower].interestRate;
        uint256 borrowAt = borrowers[_borrower].borrowAt;
        
        if (principal == 0) {
            return 0;
        }
        
        uint256 timeToUse = _timeElapsed == 0 ? 
            (block.timestamp > borrowAt ? block.timestamp - borrowAt : 0) : 
            _timeElapsed;
            
        if (timeToUse == 0) {
            return 0;
        }
        
        return (principal * interestRate * timeToUse) / (BASIS_POINTS * SECONDS_IN_YEAR);
    }

    /**
     * @param _principal The principal amount.
     * @param _timeInDays The time period in days.
     * @return interest The calculated interest for the given principal and time.
     * @notice Function to calculate interest for any principal and time period.
     * @dev Uses the contract's interest rate. Useful for front-end calculators.
     */
    function calculateInterestQuote(uint256 _principal, uint256 _timeInDays) 
        external 
        pure 
        returns (uint256 interest) 
    {
        if (_principal == 0 || _timeInDays == 0) {
            return 0;
        }
        
        uint256 timeInSeconds = _timeInDays * 1 days;
        return (_principal * INTEREST_RATE * timeInSeconds) / (BASIS_POINTS * SECONDS_IN_YEAR);
    }

    /**
     * @return maxBorrowAmount The maximum amount that can be borrowed.
     * @return interestRateBasisPoints The interest rate in basis points.
     * @return basisPointsScale The scale used for basis points (10000).
     * @notice Function to get contract constants for transparency.
     */
    function getContractConstants() 
        external 
        pure 
        returns (
            uint256 maxBorrowAmount,
            uint256 interestRateBasisPoints,
            uint256 basisPointsScale
        ) 
    {
        return (MAX_BORROW_AMOUNT, INTEREST_RATE, BASIS_POINTS);
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
}