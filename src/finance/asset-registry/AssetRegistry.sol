// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {HubOwnable} from "../base/HubOwnable.sol";
import {IPriceAggregator} from "../interfaces/IPriceAggregator.sol";

/// @title Drem Asset Registry

contract AssetRegistry is HubOwnable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IPriceAggregator private immutable PRICE_AGGREGATOR;

    EnumerableSet.AddressSet private whitelistedAssets;

    constructor(address _dremHub, address _priceAggregator) HubOwnable(_dremHub) {
        PRICE_AGGREGATOR = IPriceAggregator(_priceAggregator);
    }

    /**
     * @dev Admin function to whitelist assets
     * @param _assets the assets to whitelist
     */
    function whitelistAssets(address[] calldata _assets) external onlyHubOwner {
        if(_assets.length == 0) revert Errors.EmptyArray();

        for(uint256 i; i < _assets.length;) {
            _validateAsset(_assets[i]);
            whitelistedAssets.add(_assets[i]);
            unchecked{++i;}
        }
    }

    /**
     * @dev Admin function to remove whitelisted assets
     * @param _assets the assets to remove
     */
    function removeWhitelistedAssets(address[] calldata _assets) external onlyHubOwner {
        if(_assets.length == 0) revert Errors.EmptyArray();

        for(uint256 i; i < _assets.length; ) {
            whitelistedAssets.remove(_assets[i]);
            unchecked{++i;}
        }
    }

    /**
     * @notice returns whether or not an asset is whitelisted
     * @param _asset the asset
     * @return true if whitelisted, false if not
     */
    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return whitelistedAssets.contains(_asset);
    }

    /**
     * @notice returns all whitelisted assets
     * @return address array containing all whitelisted assets
     */

    function getWhitelistedAssets() external view returns(address[] memory) {
        return whitelistedAssets.values();
    }

    function _validateAsset(address _asset) internal view {
        if(_asset == address(0)) revert Errors.ZeroAddress();
        if(!(PRICE_AGGREGATOR.isAssetSupported(_asset))) revert Errors.AssetNotSupported();
    }
}