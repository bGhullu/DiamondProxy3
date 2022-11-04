// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct ActivatorAccount {
    // The total number of unexchanged tokens that an account has deposited into the system
    uint256 unexchangedBalance;
    // The total number of exchanged tokens that an account has had credited
    uint256 exchangedBalance;
}

// struct UpgradeActivatorAccount {
//     // The owner address whose account will be modified
//     address user;
//     // The amount to change the account's unexchanged balance by
//     int256 unexchangedBalance;
//     // The amount to change the account's exchanged balance by
//     int256 exchangedBalance;
// }

struct AppStorage {
    // @dev the synthetic token to be exchanged
    address syntheticToken;
    // @dev the underlyinToken token to be received
    address underlyingToken;
    // @dev contract pause state
    bool isPaused;
    mapping(address => ActivatorAccount) accounts;
}
