// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "../../utils/Utilities.sol";
import {console} from "../../utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";

import {FlashLoanReceiver} from "../../../Contracts/naive-receiver/FlashLoanReceiver.sol";
import {NaiveReceiverLenderPool} from "../../../Contracts/naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveReceiver is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

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
        vm.label(
            address(naiveReceiverLenderPool),
            "Naive Receiver Lender Pool"
        );
        vm.deal(address(naiveReceiverLenderPool), ETHER_IN_POOL);

        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL);
        assertEq(naiveReceiverLenderPool.fixedFee(), 1e18);

        flashLoanReceiver = new FlashLoanReceiver(
            payable(naiveReceiverLenderPool)
        );
        vm.label(address(flashLoanReceiver), "Flash Loan Receiver");
        vm.deal(address(flashLoanReceiver), ETHER_IN_RECEIVER);

        assertEq(address(flashLoanReceiver).balance, ETHER_IN_RECEIVER);

        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }

    function testExploit() public {
        /** EXPLOIT START **/

        /** EXPLOIT END **/
        validation();
    }

    function validation() internal {
        // All ETH has been drained from the receiver
        assertEq(address(flashLoanReceiver).balance, 0);
        assertEq(
            address(naiveReceiverLenderPool).balance,
            ETHER_IN_POOL + ETHER_IN_RECEIVER
        );
    }
}
