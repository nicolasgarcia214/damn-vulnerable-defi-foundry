// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {UnstoppableLender} from "./UnstoppableLender.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ReceiverUnstoppable
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract ReceiverUnstoppable {
    using SafeERC20 for IERC20;

    UnstoppableLender private immutable pool;
    address private immutable owner;

    error OnlyOwnerCanExecuteFlashLoan();
    error SenderMustBePool();

    constructor(address poolAddress) {
        pool = UnstoppableLender(poolAddress);
        owner = msg.sender;
    }

    /// @dev Pool will call this function during the flash loan
    function receiveTokens(address tokenAddress, uint256 amount) external {
        if (msg.sender != address(pool)) revert SenderMustBePool();
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function executeFlashLoan(uint256 amount) external {
        if (msg.sender != owner) revert OnlyOwnerCanExecuteFlashLoan();
        pool.flashLoan(amount);
    }
}
