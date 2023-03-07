// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Helper} from "./Helper.sol";

abstract contract Fork is Helper, Test {
    /**
     * Polygon
     */
    uint256 polygonForkId;
    string POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");
    uint256 constant POLYGON_FORK_BLOCK = 39784975;

    /**
     * Polygon aggregator contracts
     * Reference: https://docs.chain.link/data-feeds/price-feeds/addresses/?network=polygon 
     */
    AggregatorV3Interface AAVE_TO_USD_PRICE_FEED;
    AggregatorV3Interface DAI_TO_USD_PRICE_FEED;
    AggregatorV3Interface ETH_TO_USD_PRICE_FEED;
    AggregatorV3Interface MATIC_TO_USD_PRICE_FEED;
    AggregatorV3Interface USDC_TO_USD_PRICE_FEED;
    AggregatorV3Interface USDT_TO_USD_PRICE_FEED;

    function setUp() public virtual {
        vm.createSelectFork(POLYGON_RPC_URL, POLYGON_FORK_BLOCK);
        AAVE_TO_USD_PRICE_FEED = AggregatorV3Interface(0x72484B12719E23115761D5DA1646945632979bB6);
        DAI_TO_USD_PRICE_FEED = AggregatorV3Interface(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D);
        ETH_TO_USD_PRICE_FEED = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        MATIC_TO_USD_PRICE_FEED = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        USDC_TO_USD_PRICE_FEED = AggregatorV3Interface(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7);
        USDT_TO_USD_PRICE_FEED = AggregatorV3Interface(0x0A6513e40db6EB1b165753AD52E80663aeA50545); 
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
