// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBankAccount {
    function deposit(address _user) external payable;
    function withdraw(address _user, uint256 _amount) external;
    function transferFunds(address _from, address _to, uint256 _amount) external;
    function getBalance(address _user) external view returns (uint256);
    function payLoan(address _borrower, uint256 _amount) external returns (bool);
    function receiveLoan(address _borrower) external payable;
    function createAccount(address _user) external payable;
}