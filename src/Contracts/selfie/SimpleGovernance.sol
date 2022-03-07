// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/**
 * @title SimpleGovernance
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SimpleGovernance {
    using Address for address;

    struct GovernanceAction {
        address receiver;
        bytes data;
        uint256 weiAmount;
        uint256 proposedAt;
        uint256 executedAt;
    }

    DamnValuableTokenSnapshot public governanceToken;

    mapping(uint256 => GovernanceAction) public actions;
    uint256 private actionCounter;
    uint256 private constant ACTION_DELAY_IN_SECONDS = 2 days;

    event ActionQueued(uint256 actionId, address indexed caller);
    event ActionExecuted(uint256 actionId, address indexed caller);

    error GovernanceTokenCannotBeZeroAddress();
    error NotEnoughVotesToPropose();
    error CannotQueueActionsThatAffectGovernance();
    error CannotExecuteThisAction();

    constructor(address governanceTokenAddress) {
        if (governanceTokenAddress == address(0))
            revert GovernanceTokenCannotBeZeroAddress();

        governanceToken = DamnValuableTokenSnapshot(governanceTokenAddress);
        actionCounter = 1;
    }

    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256) {
        if (!_hasEnoughVotes(msg.sender)) revert NotEnoughVotesToPropose();
        if (receiver == address(this))
            revert CannotQueueActionsThatAffectGovernance();

        uint256 actionId = actionCounter;

        GovernanceAction storage actionToQueue = actions[actionId];
        actionToQueue.receiver = receiver;
        actionToQueue.weiAmount = weiAmount;
        actionToQueue.data = data;
        actionToQueue.proposedAt = block.timestamp;

        actionCounter++;

        emit ActionQueued(actionId, msg.sender);
        return actionId;
    }

    function executeAction(uint256 actionId) external payable {
        if (!_canBeExecuted(actionId)) revert CannotExecuteThisAction();

        GovernanceAction storage actionToExecute = actions[actionId];
        actionToExecute.executedAt = block.timestamp;

        actionToExecute.receiver.functionCallWithValue(
            actionToExecute.data,
            actionToExecute.weiAmount
        );

        emit ActionExecuted(actionId, msg.sender);
    }

    function getActionDelay() public pure returns (uint256) {
        return ACTION_DELAY_IN_SECONDS;
    }

    /**
     * @dev an action can only be executed if:
     * 1) it's never been executed before and
     * 2) enough time has passed since it was first proposed
     */
    function _canBeExecuted(uint256 actionId) private view returns (bool) {
        GovernanceAction memory actionToExecute = actions[actionId];
        return (actionToExecute.executedAt == 0 &&
            (block.timestamp - actionToExecute.proposedAt >=
                ACTION_DELAY_IN_SECONDS));
    }

    function _hasEnoughVotes(address account) private view returns (bool) {
        uint256 balance = governanceToken.getBalanceAtLastSnapshot(account);
        uint256 halfTotalSupply = governanceToken
            .getTotalSupplyAtLastSnapshot() / 2;
        return balance > halfTotalSupply;
    }
}
