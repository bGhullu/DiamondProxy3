// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../libraries/TokenUtils.sol";
import "../base/Error.sol";
import "../libraries/SafeCast.sol";
import "../libraries/AppStorage.sol";

/**
 * @title Activator
 * @notice A contract which facilitates the exchange of synthetic assets for their underlying
 * asset. This contract guarantees that synthetic assets are exchanged exactly 1:1
 * for the underlying asset.
 */

contract ActivatorFacet is Initializable, ReentrancyGuardUpgradeable {
    AppStorage s;

    struct UpdateActivatorAccount {
        // The owner address whose account will be modified
        address user;
        // The amount to change the account's unexchanged balance by
        int256 unexchangedBalance;
        // The amount to change the account's exchanged balance by
        int256 exchangedBalance;
    }

    /**
     * @notice Emitted when the system is paused or unpaused.
     * @param flag `true` if the system has been paused, `false` otherwise.
     */
    event Paused(bool flag);

    event Deposit(address indexed user, uint256 unexchangedBalance);

    event Withdraw(
        address indexed user,
        uint256 unexchangedBalance,
        uint256 exchangedBalance
    );

    event Claim(
        address indexed user,
        uint256 unexchangedBalance,
        uint256 exchangedBalance
    );

    constructor() {}

    function initialize(address _syntheticToken, address _underlyingToken)
        external
        initializer
    {
        LibDiamond.enforceIsContractOwner();
        s.syntheticToken = _syntheticToken;
        s.underlyingToken = _underlyingToken;
        s.isPaused = false;
    }

    // @dev A modifier which checks whether the Activator is unpaused.
    modifier notPaused() {
        if (s.isPaused) {
            revert IllegalState();
        }
        _;
    }

    function setPause(bool pauseState) external {
        LibDiamond.enforceIsContractOwner();
        s.isPaused = pauseState;
        emit Paused(s.isPaused);
    }

    function depositSynthetic(uint256 amount) external nonReentrant {
        _updateAccount(
            UpdateActivatorAccount({
                user: msg.sender,
                unexchangedBalance: SafeCast.toInt256(amount),
                exchangedBalance: 0
            })
        );
        TokenUtils.safeTransferFrom(
            s.syntheticToken,
            msg.sender,
            address(this),
            amount
        );
        emit Deposit(msg.sender, amount);
    }

    function withdrawSynthetic(uint256 amount) external nonReentrant {
        _updateAccount(
            UpdateActivatorAccount({
                user: msg.sender,
                unexchangedBalance: -SafeCast.toInt256(amount),
                exchangedBalance: 0
            })
        );
        TokenUtils.safeTransfer(s.syntheticToken, msg.sender, amount);
        emit Withdraw(
            msg.sender,
            s.accounts[msg.sender].unexchangedBalance,
            s.accounts[msg.sender].exchangedBalance
        );
    }

    function claimUnderlying(uint256 amount) external nonReentrant {
        _updateAccount(
            UpdateActivatorAccount({
                user: msg.sender,
                unexchangedBalance: -SafeCast.toInt256(amount),
                exchangedBalance: SafeCast.toInt256(amount)
            })
        );
        TokenUtils.safeTransfer(s.underlyingToken, msg.sender, amount);
        TokenUtils.safeBurn(s.syntheticToken, amount);
        emit Claim(
            msg.sender,
            s.accounts[msg.sender].unexchangedBalance,
            s.accounts[msg.sender].exchangedBalance
        );
    }

    function _updateAccount(UpdateActivatorAccount memory param) internal {
        ActivatorAccount storage _account = s.accounts[param.user];
        int256 updateUnexchange = int256(_account.unexchangedBalance) +
            param.unexchangedBalance;
        int256 updateExchange = int256(_account.exchangedBalance) +
            param.exchangedBalance;
        if (updateUnexchange < 0 || updateExchange < 0) {
            revert IllegalState();
        }
        _account.unexchangedBalance = uint256(updateUnexchange);
        _account.exchangedBalance = uint256(updateExchange);
    }

    function getSyntheticToken() external view returns (address) {
        return s.syntheticToken;
    }

    function getUnderlyingToken() external view returns (address) {
        return s.underlyingToken;
    }

    function getUserData(address user)
        external
        view
        returns (uint256, uint256)
    {
        ActivatorAccount storage _account = s.accounts[user];
        uint256 unexchange = _account.unexchangedBalance;
        uint256 exchange = _account.exchangedBalance;
        return (unexchange, exchange);
    }

    function getBalance(address token, address account)
        external
        view
        returns (uint256)
    {
        return TokenUtils.safeBalanceOf(token, account);
    }
}
