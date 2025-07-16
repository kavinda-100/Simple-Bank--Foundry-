// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBankAccount {
    function deposit(address _user) external payable;
    function withdraw(uint256 _amount) external;
    function transferFunds(address _to, uint256 _amount) external;
    function freezeAccount(address _account) external;
    function activateAccount(address _account) external;
    function getBalance(address _owner) external view returns (uint256);
    function isAccountActive(address _owner) external view returns (bool);
}