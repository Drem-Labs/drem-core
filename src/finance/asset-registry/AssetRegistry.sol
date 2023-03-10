// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {HubOwnable} from "../base/HubOwnable.sol";
import {IPriceAggregator} from "../interfaces/IPriceAggregator.sol";

/// @title Drem Asset Registry

contract AssetRegistry is HubOwnable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Debatable whether should be in init function or should remain as immutable 
    IPriceAggregator private immutable PRICE_AGGREGATOR;

    EnumerableSet.AddressSet private whitelistedAssets;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    constructor(address _dremHub, address _priceAggregator) HubOwnable(_dremHub) {
        PRICE_AGGREGATOR = IPriceAggregator(_priceAggregator);
    }

    /**
     * @dev Admin function to whitelist assets
     * @param _assets the assets to whitelist
     */
    function whitelistAssets(address[] calldata _assets) external onlyHubOwner {
        uint256 len = _assets.length;
        
        if(len == 0) revert Errors.EmptyArray();

        for(uint256 i; i < len;) {
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
        uint256 len = _assets.length;
        
        if(len == 0) revert Errors.EmptyArray();

        for(uint256 i; i < len; ) {
            if(!(whitelistedAssets.contains(_assets[i]))) revert Errors.AssetNotWhitelisted();
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

    function getPriceAggregator() external view returns(IPriceAggregator) {
        return PRICE_AGGREGATOR;
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
        if(whitelistedAssets.contains(_asset)) revert Errors.AssetAlreadyWhitelisted();
    }

    function _authorizeUpgrade(address) internal virtual override onlyHubOwner{}
}