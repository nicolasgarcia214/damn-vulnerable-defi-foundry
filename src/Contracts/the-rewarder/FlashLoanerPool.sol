// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @dev A simple pool to get flash loans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable liquidityToken;

    error NotEnoughTokensInPool();
    error FlashLoanHasNotBeenPaidBack();
    error BorrowerMustBeAContract();

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function flashLoan(uint256 amount) external nonReentrant {
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));
        if (amount > balanceBefore) revert NotEnoughTokensInPool();
        if (!msg.sender.isContract()) revert BorrowerMustBeAContract();

        liquidityToken.transfer(msg.sender, amount);

        msg.sender.functionCall(
            abi.encodeWithSignature("receiveFlashLoan(uint256)", amount)
        );

        if (liquidityToken.balanceOf(address(this)) < balanceBefore)
            revert FlashLoanHasNotBeenPaidBack();
    }
}
