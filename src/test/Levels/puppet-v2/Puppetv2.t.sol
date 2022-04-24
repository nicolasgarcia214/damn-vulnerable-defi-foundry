// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "../../utils/Utilities.sol";
import {console} from "../../utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdCheats} from "forge-std/stdlib.sol";

import {DamnValuableToken} from "../../../Contracts/DamnValuableToken.sol";
import {WETH9} from "../../../Contracts/WETH9.sol";

import {PuppetV2Pool} from "../../../Contracts/puppet-v2/PuppetV2Pool.sol";


interface UniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address);
    function getPair(address token0, address token1) external view returns (address);
}


interface UniswapV2Pair {
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function initialize(address _token0, address _token1) external;
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function token0() external view returns (address);
    function token1() external view returns (address);

    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

}


interface UniswapV2Router02 {
    // function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256, uint256, uint256);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256, uint256, uint256);


}




contract PuppetV2 is DSTest, stdCheats {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    // Uniswap exchange will start with 100 DVT and 10 WETH in liquidity
    uint256 internal constant UNISWAP_INITIAL_TOKEN_RESERVE = 100e18;
    uint256 internal constant UNISWAP_INITIAL_WETH_RESERVE = 10e18;

    // attacker will start with 10_000 DVT and 20 ETH
    uint256 internal constant ATTACKER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 internal constant ATTACKER_INITIAL_ETH_BALANCE = 20e18;

    // pool will start with 1_000_000 DVT
    uint256 internal constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;
    uint256 internal constant DEADLINE = 10_000_000;

    UniswapV2Pair internal uniswapV2Pair;
    UniswapV2Factory internal uniswapV2Factory;
    UniswapV2Router02 internal uniswapV2Router;

    DamnValuableToken internal dvt;
    WETH9 internal weth;

    PuppetV2Pool internal puppetV2Pool;
    address payable internal attacker;
    address payable internal deployer;

    function setUp() public {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        attacker = payable(
            address(uint160(uint256(keccak256(abi.encodePacked("attacker")))))
        );
        vm.label(attacker, "Attacker");
        vm.deal(attacker, ATTACKER_INITIAL_ETH_BALANCE);

        deployer = payable(
            address(uint160(uint256(keccak256(abi.encodePacked("deployer")))))
        );
        vm.label(deployer, "deployer");
        vm.deal(deployer, UNISWAP_INITIAL_WETH_RESERVE);


        // Deploy token to be traded in Uniswap
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        weth = new WETH9();
        vm.label(address(weth), "WETH");



        // Deploy Uniswap Factory and Router
        uniswapV2Factory = UniswapV2Factory(
            deployCode(
                "./src/build-uniswap/v2/UniswapV2Factory.json", 
                abi.encode(address(0))
            )
        );

        uniswapV2Router = UniswapV2Router02(
            deployCode(
                "./src/build-uniswap/v2/UniswapV2Router02.json",
                abi.encode(address(uniswapV2Factory), address(weth))
            )
        );


        // Create Uniswap pair against WETH and add liquidity
        dvt.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}(
            address(dvt),
            UNISWAP_INITIAL_TOKEN_RESERVE,              // amountTokenDesired
            0,                                          // amountTokenMin
            0,                                          // amountETHMin
            deployer,                                   // to
            DEADLINE                                    // deadline
        );

        // Get a reference to the created Uniswap pair
        uniswapV2Pair = UniswapV2Pair(
            uniswapV2Factory.getPair(address(dvt), address(weth))
        );

        assertEq(uniswapV2Pair.token0(), address(weth));
        assertEq(uniswapV2Pair.token1(), address(dvt));
        assertGt(uniswapV2Pair.balanceOf(deployer), 0);

        // Deploy the lending pool
        puppetV2Pool = new PuppetV2Pool(
            address(weth), 
            address(dvt), 
            address(uniswapV2Pair), 
            address(uniswapV2Factory)
        );


        // Setup initial token balances of pool and attacker account
        dvt.transfer(attacker, ATTACKER_INITIAL_TOKEN_BALANCE);
        dvt.transfer(address(puppetV2Pool), POOL_INITIAL_TOKEN_BALANCE);


        // Ensure correct setup of pool.
        assertEq(
            puppetV2Pool.calculateDepositOfWETHRequired(1 ether),
            0.3 ether
        );

        assertEq(
            puppetV2Pool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE),
            300000 ether
        );

        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }


    function testExploit() public {
        /** EXPLOIT START **/

        /** EXPLOIT END **/
        validation();
    }


    function validation() internal {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        assertEq(dvt.balanceOf(attacker), POOL_INITIAL_TOKEN_BALANCE);
        assertEq(dvt.balanceOf(address(puppetV2Pool)), 0);

    }




}