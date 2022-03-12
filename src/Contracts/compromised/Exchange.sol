// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

import {TrustfulOracle} from "./TrustfulOracle.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";

/**
 * @title Exchange
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Exchange is ReentrancyGuard {
    using Address for address payable;

    DamnValuableNFT public immutable token;
    TrustfulOracle public immutable oracle;

    event TokenBought(address indexed buyer, uint256 tokenId, uint256 price);
    event TokenSold(address indexed seller, uint256 tokenId, uint256 price);

    error NotEnoughETHInBalance();
    error AmountPaidIsNotEnough();
    error ValueMustBeGreaterThanZero();
    error SellerMustBeTheOwner();
    error SellerMustHaveApprovedTransfer();

    constructor(address oracleAddress) payable {
        token = new DamnValuableNFT();
        oracle = TrustfulOracle(oracleAddress);
    }

    function buyOne() external payable nonReentrant returns (uint256) {
        uint256 amountPaidInWei = msg.value;
        if (amountPaidInWei == 0) revert ValueMustBeGreaterThanZero();

        // Price should be in [wei / NFT]
        uint256 currentPriceInWei = oracle.getMedianPrice(token.symbol());
        if (amountPaidInWei < currentPriceInWei) revert AmountPaidIsNotEnough();

        uint256 tokenId = token.safeMint(msg.sender);

        payable(msg.sender).sendValue(amountPaidInWei - currentPriceInWei);

        emit TokenBought(msg.sender, tokenId, currentPriceInWei);

        return tokenId;
    }

    function sellOne(uint256 tokenId) external nonReentrant {
        if (msg.sender != token.ownerOf(tokenId)) revert SellerMustBeTheOwner();
        if (token.getApproved(tokenId) != address(this))
            revert SellerMustHaveApprovedTransfer();

        // Price should be in [wei / NFT]
        uint256 currentPriceInWei = oracle.getMedianPrice(token.symbol());
        if (address(this).balance < currentPriceInWei)
            revert NotEnoughETHInBalance();

        token.transferFrom(msg.sender, address(this), tokenId);
        token.burn(tokenId);

        payable(msg.sender).sendValue(currentPriceInWei);

        emit TokenSold(msg.sender, tokenId, currentPriceInWei);
    }

    receive() external payable {}
}
