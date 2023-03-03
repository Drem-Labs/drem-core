// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {HubOwnable} from "../base/HubOwnable.sol";
import {IPriceAggregator} from "../interfaces/IPriceAggregator.sol";


/**
 * Specs:
 *   - Needs to be able to calculate the rates between two different assets supported by chainlink
 *   and subsequently spit out a ETH or USD value
 *   - Needs to calculate the value of positions in AAVE, Uniswap, etc.
 *   - Shouldn't everything just be converted to ETH price, since it's the most supported?
 *   - Need to check if the rate is stale...
 */

 contract PriceAggregator is IPriceAggregator, HubOwnable {

    uint256 private constant CHAINLINK_DECIMALS = 8;
    // Either should be 31 seconds or 24 hours + 1
    uint256 private constant STAGNANT_RATE_LIMIT = 31;
    // Reference: https://polygonscan.com/address/0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    constructor (address _dremHub) HubOwnable(_dremHub) {}

    enum RateAsset{
        USD,
        ETH
    }

    struct SupportedAssetInfo {
        AggregatorV3Interface aggregator;
        RateAsset rateAsset;
        uint256 units; // To use units or decimals here...  Prob units...
    }

    mapping(address => SupportedAssetInfo) assetToInfo;

    function addSupportedAsset(address _asset, AggregatorV3Interface _aggregator, RateAsset _rateAsset) external onlyHubOwner {
        uint256 _units = 10 ** (ERC20(_asset).decimals());

        
        assetToInfo[_asset] = SupportedAssetInfo({
            aggregator: _aggregator,
            rateAsset: _rateAsset,
            units: _units
        });
    }

    function removeSupportedAsset(address _asset) external onlyHubOwner {
        delete assetToInfo[_asset];
    }

    function getAssetPrice(address denominationAsset, address outputAsset) external view {}

    function isAssetSupported(address _asset) external view returns(bool) {
        return address(assetToInfo[_asset].aggregator) != address(0);
    }

    function getSupportedAssetInfo(address _asset) external view returns (SupportedAssetInfo memory) {
        return assetToInfo[_asset];
    }

    function _getLatestPrice() internal view {}
 }