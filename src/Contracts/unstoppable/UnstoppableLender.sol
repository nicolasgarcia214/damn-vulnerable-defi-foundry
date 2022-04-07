// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title DamnValuableToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract UnstoppableLender is ReentrancyGuard {
    IERC20 public immutable damnValuableToken;
    uint256 public poolBalance;

    error MustDepositOneTokenMinimum();
    error TokenAddressCannotBeZero();
    error MustBorrowOneTokenMinimum();
    error NotEnoughTokensInPool();
    error FlashLoanHasNotBeenPaidBack();
    error AssertionViolated();

    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) revert TokenAddressCannotBeZero();
        damnValuableToken = IERC20(tokenAddress);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        if (amount == 0) revert MustDepositOneTokenMinimum();
        // Transfer token from sender. Sender must have first approved them.
        damnValuableToken.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance + amount;
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        if (borrowAmount == 0) revert MustBorrowOneTokenMinimum();

        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        if (balanceBefore < borrowAmount) revert NotEnoughTokensInPool();

        // Ensured by the protocol via the `depositTokens` function
        if (poolBalance != balanceBefore) revert AssertionViolated();

        damnValuableToken.transfer(msg.sender, borrowAmount);

        IReceiver(msg.sender).receiveTokens(
            address(damnValuableToken),
            borrowAmount
        );

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
    }
}

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}
