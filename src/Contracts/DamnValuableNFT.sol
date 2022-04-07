// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "openzeppelin-contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {Counters} from "openzeppelin-contracts/utils/Counters.sol";

/**
 * @title DamnValuableNFT
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @notice Implementation of a mintable and burnable NFT with role-based access controls
 */
contract DamnValuableNFT is ERC721, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("DamnValuableNFT", "DVNFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address to)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        return tokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
