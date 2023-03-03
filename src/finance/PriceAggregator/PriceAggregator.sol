// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IPriceAggregator} from "../interfaces/IPriceAggregator.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * Specs:
 *   - Needs to be able to calculate the rates between two different assets supported by chainlink
 *   and subsequently spit out a ETH or USD value
 *   - Needs to calculate the value of positions in AAVE, Uniswap, etc.
 *   - Shouldn't everything just be converted to ETH price, since it's the most supported?
 *   - Need to check if the rate is stale...
 */

 contract PriceAggregator is IPriceAggregator {

    uint256 private constant CHAINLINK_DECIMALS = 8;
    // Either should be 31 seconds or 24 hours + 1
    uint256 private constant STAGNANT_RATE_LIMIT = 31;
    // Reference: https://polygonscan.com/address/0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address immutable DREM_HUB;

    constructor (address _dremHub) {
        DREM_HUB = _dremHub;
    }

    enum RateAsset{
        USD,
        ETH
    }

    struct AggregatorInfo {
        AggregatorV3Interface aggregatorAddress;
        RateAsset rateAsset;
    }

    struct SupportedAssetInfo {
        address supportedAsset;
        address aggregatorAddress;
        RateAsset rateAsset;
        uint256 decimals; // To use units or decimals here...  Prob units...
    }

    mapping(address => uint256) supportedAssetToUnit;
    mapping(address => address) supportedAssetToAggregator;

    function addSupportedAsset() external {}

    function getAssetPrice(address denominationAsset, address outputAsset) external view {}

    function _getLatestPrice() internal view {}
 }