// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBankAccount {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function transferFunds(address _to, uint256 _amount) external;
    function freezeAccount() external;
    function activateAccount() external;
}