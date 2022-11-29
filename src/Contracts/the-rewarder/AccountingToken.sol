// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20Snapshot, ERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

/**
 * @title AccountingToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @notice A limited pseudo-ERC20 token to keep track of deposits and withdrawals
 *         with snapshotting capabilities
 */
contract AccountingToken is ERC20Snapshot, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    error Forbidden();
    error NotImplemented();

    constructor() ERC20("rToken", "rTKN") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert Forbidden();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (!hasRole(BURNER_ROLE, msg.sender)) revert Forbidden();
        _burn(from, amount);
    }

    function snapshot() external returns (uint256) {
        if (!hasRole(SNAPSHOT_ROLE, msg.sender)) revert Forbidden();
        return _snapshot();
    }

    // Do not need transfer of this token
    function _transfer(address, address, uint256) internal pure override {
        revert NotImplemented();
    }

    // Do not need allowance of this token
    function _approve(address, address, uint256) internal pure override {
        revert NotImplemented();
    }
}
