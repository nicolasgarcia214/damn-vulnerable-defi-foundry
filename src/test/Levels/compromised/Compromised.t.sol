// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "../../utils/Utilities.sol";
import {console} from "../../utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";

import "../../../Contracts/compromised/TrustfulOracleInitializer.sol";
import "../../../Contracts/compromised/TrustfulOracle.sol";
import "../../../Contracts/compromised/Exchange.sol";

contract Compromised is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 internal constant EXCHANGE_INITIAL_ETH_BALANCE = 9_990e18;
    uint256 internal constant INITIAL_NFT_PRICE = 990e18;

    address[] internal sources = [
        0xA73209FB1a42495120166736362A1DfA9F95A105,
        0xe92401A4d3af5E446d93D11EEc806b1462b39D15,
        0x81A5D6E50C214044bE44cA0CB057fe119097850c
    ];
    string[] internal symbols;
    uint256[] internal initialPrices;

    Utilities internal utils;
    TrustfulOracle internal oracle;
    Exchange internal exchange;
    DamnValuableNFT internal nft;

    address payable internal attacker;

    function setUp() public {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        utils = new Utilities();
        attacker = utils.createUsers(1)[0];

        vm.label(attacker, "Attacker");

        // Initialize balance of the trusted source addresses
        for (uint8 i; i < sources.length; i++) {
            vm.deal(sources[i], 2e18);
            assertEq(sources[i].balance, 2e18);
        }

        // Attacker starts with 0.1 ETH in balance
        vm.deal(attacker, 1e17);
        assertEq(attacker.balance, 1e17);

        // Deploy the oracle and setup the trusted sources with initial prices
        for (uint8 i; i < 3; i++) {
            symbols.push("DVNFT");
            initialPrices.push(INITIAL_NFT_PRICE);
        }

        TrustfulOracleInitializer trustfulOracleInitializer = new TrustfulOracleInitializer(
                sources,
                symbols,
                initialPrices
            );
        oracle = trustfulOracleInitializer.oracle();

        // Deploy exchange and set initial balance
        exchange = new Exchange(address(oracle));
        vm.deal(address(exchange), EXCHANGE_INITIAL_ETH_BALANCE);
        assertEq(address(exchange).balance, EXCHANGE_INITIAL_ETH_BALANCE);

        nft = exchange.token();

        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }

    function testExploit() public {
        /** EXPLOIT START **/

        /** EXPLOIT END **/
        testAfter();
    }

    function testAfter() public {
        /** SUCCESS CONDITIONS */

        // Exchange must have lost all ETH
        assertEq(address(exchange).balance, 0);

        // Attacker's ETH balance must have significantly increased
        assertGt(address(attacker).balance, EXCHANGE_INITIAL_ETH_BALANCE);

        // Attacker must not own any NFT
        assertEq(nft.balanceOf(attacker), 0);

        // NFT price shouldn't have changed
        assertEq(oracle.getMedianPrice("DVNFT"), INITIAL_NFT_PRICE);
    }
}
