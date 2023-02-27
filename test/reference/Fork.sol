// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {Helper} from "./Helper.sol";

contract Fork is Helper, Test {
     /**
      * Polygon
      */
    uint256 polygonForkId;
    string POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");
    uint256 constant POLYGON_FORK_BLOCK = 39784975;


    function setUp() public virtual {
        vm.createSelectFork(POLYGON_RPC_URL);
        // USDC_PER_ETH_PRICE_FEED = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        // USDC_PER_BTC_PRICE_FEED = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        // WBTC_PER_BTC_PRICE_FEED = AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    }

    // function getEthToUSDCPriceAndDecimals() internal view returns (int256, uint8) {
    //     (
    //         /* uint80 roundID */
    //         ,
    //         int256 price,
    //         /*uint startedAt*/
    //         ,
    //         /*uint timeStamp*/
    //         ,
    //         /*uint80 answeredInRound*/
    //     ) = USDC_PER_ETH_PRICE_FEED.latestRoundData();

    //     require(price > 0, "Negative price value");

    //     uint8 decimals = USDC_PER_ETH_PRICE_FEED.decimals();

    //     return (price, decimals);
    // }

    // function getBtcToUSDCPriceAndDecimals() internal view returns (int256, uint8) {
    //     (
    //         /* uint80 roundID */
    //         ,
    //         int256 price,
    //         /*uint startedAt*/
    //         ,
    //         /*uint timeStamp*/
    //         ,
    //         /*uint80 answeredInRound*/
    //     ) = USDC_PER_BTC_PRICE_FEED.latestRoundData();

    //     require(price > 0, "Negative price value");

    //     uint8 decimals = USDC_PER_BTC_PRICE_FEED.decimals();

    //     return (price, decimals);
    // }

    // function getWbtcToBtcConversionRateAndDecimals() internal view returns (int256, uint8) {
    //     (
    //         /* uint80 roundID */
    //         ,
    //         int256 price,
    //         /*uint startedAt*/
    //         ,
    //         /*uint timeStamp*/
    //         ,
    //         /*uint80 answeredInRound*/
    //     ) = WBTC_PER_BTC_PRICE_FEED.latestRoundData();

    //     require(price > 0, "Negative price value");

    //     uint8 decimals = WBTC_PER_BTC_PRICE_FEED.decimals();

    //     return (price, decimals);
    // }

    // /**
    //  * @dev Can only be used when the vm is forked from mainnet
    //  * Issues an amount of USDC given an address
    //  * Requirements:
    //  *     - The address cannot be address(0)
    //  *     - The address cannot be blacklisted by USDC
    //  */
    // function issueUSDC(address _address, uint256 _amount) internal {
    //     // Set msg.sender temporarily to the owner of the USDC contracts
    //     vm.startPrank(USDC_MASTER_MINTER);

    //     IUSDC(USDC_ADDRESS).configureMinter(USDC_MASTER_MINTER, _amount);

    //     IUSDC(USDC_ADDRESS).mint(_address, _amount);

    //     assertGe(IUSDC(USDC_ADDRESS).balanceOf(_address), _amount);
    //     // Set msg.sender to back to normal
    //     vm.stopPrank();
    // }

    // /**
    //  * @dev Internal function to get token balances from 3 different addresses
    //  */
    // function getTokenBalances(IERC20 token, address first, address second, address third)
    //     internal
    //     view
    //     returns (uint256, uint256, uint256)
    // {
    //     return (token.balanceOf(first), token.balanceOf(second), token.balanceOf(third));
    // }
}
