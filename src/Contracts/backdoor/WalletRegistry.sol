// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {IProxyCreationCallback} from "gnosis/proxies/IProxyCreationCallback.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";

/**
 * @title WalletRegistry
 * @notice A registry for Gnosis Safe wallets.
           When known beneficiaries deploy and register their wallets, the registry sends some Damn Valuable Tokens to the wallet.
 * @dev The registry has embedded verifications to ensure only legitimate Gnosis Safe wallets are stored.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract WalletRegistry is IProxyCreationCallback, Ownable {
    uint256 private constant MAX_OWNERS = 1;
    uint256 private constant MAX_THRESHOLD = 1;
    uint256 private constant TOKEN_PAYMENT = 10 ether; // 10 * 10 ** 18

    address public immutable masterCopy;
    address public immutable walletFactory;
    IERC20 public immutable token;

    mapping(address => bool) public beneficiaries;

    // owner => wallet
    mapping(address => address) public wallets;

    error AddressZeroIsNotAllowed();
    error NotEnoughFundsToPay();
    error CallerMustBeFactory();
    error FakeMasterCopyUsed();
    error WrongInitialization();
    error InvalidThreshold();
    error InvalidNumberOfOwners();
    error OwnerIsNotRegisteredAsBeneficiary();

    constructor(
        address masterCopyAddress,
        address walletFactoryAddress,
        address tokenAddress,
        address[] memory initialBeneficiaries
    ) {
        if (masterCopyAddress == address(0)) revert AddressZeroIsNotAllowed();
        if (walletFactoryAddress == address(0))
            revert AddressZeroIsNotAllowed();

        masterCopy = masterCopyAddress;
        walletFactory = walletFactoryAddress;
        token = IERC20(tokenAddress);

        for (uint256 i = 0; i < initialBeneficiaries.length; i++) {
            addBeneficiary(initialBeneficiaries[i]);
        }
    }

    function addBeneficiary(address beneficiary) public onlyOwner {
        beneficiaries[beneficiary] = true;
    }

    function _removeBeneficiary(address beneficiary) private {
        beneficiaries[beneficiary] = false;
    }

    /**
     @notice Function executed when user creates a Gnosis Safe wallet via GnosisSafeProxyFactory::createProxyWithCallback
             setting the registry's address as the callback.
     */
    function proxyCreated(
        GnosisSafeProxy proxy,
        address singleton,
        bytes calldata initializer,
        uint256
    ) external override {
        // Make sure we have enough DVT to pay
        if (token.balanceOf(address(this)) < TOKEN_PAYMENT)
            revert NotEnoughFundsToPay();

        address payable walletAddress = payable(proxy);

        // Ensure correct factory and master copy
        if (msg.sender != walletFactory) revert CallerMustBeFactory();
        if (singleton != masterCopy) revert FakeMasterCopyUsed();

        // Ensure initial calldata was a call to `GnosisSafe::setup`
        if (bytes4(initializer[:4]) != GnosisSafe.setup.selector)
            revert WrongInitialization();

        // Ensure wallet initialization is the expected
        if (GnosisSafe(walletAddress).getThreshold() != MAX_THRESHOLD)
            revert InvalidThreshold();

        if (GnosisSafe(walletAddress).getOwners().length != MAX_OWNERS)
            revert InvalidNumberOfOwners();

        // Ensure the owner is a registered beneficiary
        address walletOwner = GnosisSafe(walletAddress).getOwners()[0];

        if (!beneficiaries[walletOwner])
            revert OwnerIsNotRegisteredAsBeneficiary();

        // Remove owner as beneficiary
        _removeBeneficiary(walletOwner);

        // Register the wallet under the owner's address
        wallets[walletOwner] = walletAddress;

        // Pay tokens to the newly created wallet
        token.transfer(walletAddress, TOKEN_PAYMENT);
    }
}
