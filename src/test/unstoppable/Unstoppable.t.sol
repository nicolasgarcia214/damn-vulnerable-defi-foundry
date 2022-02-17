// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "../utils/Utilities.sol";
import {console} from "../utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";

import {DamnValuableToken} from "../../DamnValuableToken.sol";
import {UnstoppableLender} from "../../unstoppable/UnstoppableLender.sol";
import {ReceiverUnstoppable} from "../../unstoppable/ReceiverUnstoppable.sol";

contract Unstoppable is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;
    uint256 internal constant INITIAL_ATTACKER_TOKEN_BALANCE = 100e18;

    Utilities internal utils;
    UnstoppableLender internal unstoppableLender;
    ReceiverUnstoppable internal receiverUnstoppable;
    DamnValuableToken internal dvt;
    address payable internal deployer;
    address payable internal attacker;
    address payable internal someUser;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(3);
        deployer = users[0];
        attacker = users[1];
        someUser = users[2];

        dvt = new DamnValuableToken();
        unstoppableLender = new UnstoppableLender(address(dvt));

        dvt.approve(address(unstoppableLender), TOKENS_IN_POOL);
        unstoppableLender.depositTokens(TOKENS_IN_POOL);

        dvt.transfer(attacker, INITIAL_ATTACKER_TOKEN_BALANCE);

        assertEq(dvt.balanceOf(address(unstoppableLender)), TOKENS_IN_POOL);
        assertEq(dvt.balanceOf(attacker), INITIAL_ATTACKER_TOKEN_BALANCE);

        vm.startPrank(someUser);
        receiverUnstoppable = new ReceiverUnstoppable(
            address(unstoppableLender)
        );
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }

    function testFailExploit() public {
        /** EXPLOIT START **/

        /** EXPLOIT END **/
        testFailAfter();
    }

    function testFailAfter() public {
        vm.startPrank(someUser);
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
    }
}
