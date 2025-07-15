// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBankAccount {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function transferFunds(address _to, uint256 _amount) external;
    function freezeAccount(address _admin) external;
    function activateAccount(address _admin) external;
    function getBalance(address _owner) external view returns (uint256);
    function isAccountActive(address _owner) external view returns (bool);
}