// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {HubOwnable} from "../base/HubOwnable.sol";
import {IPriceAggregator} from "../interfaces/IPriceAggregator.sol";

/// @title Drem Asset Registry

/**
 * Invariants:
 *  - An asset can be a denomination asset if and only if it is whitelisted
 */

contract AssetRegistry is HubOwnable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Debatable whether should be in init function or should remain as immutable
    IPriceAggregator private immutable PRICE_AGGREGATOR;

    EnumerableSet.AddressSet private whitelistedAssets;

    EnumerableSet.AddressSet private denominationAssets;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    // To do: set PRICE_AGGREGATOR in storage in place of immutable
    constructor(address _dremHub, address _priceAggregator) HubOwnable(_dremHub) {
        PRICE_AGGREGATOR = IPriceAggregator(_priceAggregator);
    }

    /**
     * @dev Admin function to add denomination assets
     * @param _denominationAssets the denomination assets to add
     */
    function addDenominationAssets(address[] calldata _denominationAssets) external onlyHubOwner {
        _validateArray(_denominationAssets);

        for (uint256 i; i < _denominationAssets.length;) {
            _validateAsset(_denominationAssets[i]);
            // Denomination asset must be whitelisted
            if (!(whitelistedAssets.contains(_denominationAssets[i]))) revert Errors.AssetNotWhitelisted();
            if (denominationAssets.contains(_denominationAssets[i])) revert Errors.AssetAlreadyDenominationAsset();

            denominationAssets.add(_denominationAssets[i]);

            unchecked {
                ++i;
            }
        }

        emit Events.DenominationAssetsAdded(_denominationAssets);
    }

    /**
     * @dev Admin function to remove denomination assets
     * @param _denominationAssets the denomination assets to remove
     */
    function removeDenominationAssets(address[] calldata _denominationAssets) external onlyHubOwner {
        _validateArray(_denominationAssets);

        for (uint256 i; i < _denominationAssets.length;) {
            if (_denominationAssets[i] == address(0)) revert Errors.ZeroAddress();
            if (!(denominationAssets.contains(_denominationAssets[i]))) revert Errors.AssetNotDenominationAsset();

            denominationAssets.remove(_denominationAssets[i]);

            unchecked {
                ++i;
            }
        }

        emit Events.DenominationAssetsRemoved(_denominationAssets);
    }

    /**
     * @dev Admin function to whitelist assets
     * @param _assets the assets to whitelist
     */
    function whitelistAssets(address[] calldata _assets) external onlyHubOwner {
        _validateArray(_assets);

        for (uint256 i; i < _assets.length;) {
            if (whitelistedAssets.contains(_assets[i])) revert Errors.AssetAlreadyWhitelisted();
            _validateAsset(_assets[i]);

            whitelistedAssets.add(_assets[i]);

            unchecked {
                ++i;
            }
        }

        emit Events.WhitelistedAssetsAdded(_assets);
    }

    /**
     * @dev Admin function to remove whitelisted assets
     * @param _assets the assets to remove
     */
    function removeWhitelistedAssets(address[] calldata _assets) external onlyHubOwner {
        _validateArray(_assets);

        for (uint256 i; i < _assets.length;) {
            if (_assets[i] == address(0)) revert Errors.ZeroAddress();
            if (!(whitelistedAssets.contains(_assets[i]))) revert Errors.AssetNotWhitelisted();

            whitelistedAssets.remove(_assets[i]);

            unchecked {
                ++i;
            }
        }

        emit Events.WhitelistedAssetsRemoved(_assets);
    }

    /**
     * @notice returns whether or not an asset is a denomination asset
     * @param _asset the asset
     * @return true if whitelisted, false if not
     */
    function isAssetDenominationAsset(address _asset) external view returns (bool) {
        return _isAssetWhitelisted(_asset) && denominationAssets.contains(_asset);
    }

    /**
     * @notice returns whether or not an asset is whitelisted
     * @param _asset the asset
     * @return true if whitelisted, false if not
     */
    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return _isAssetWhitelisted(_asset);
    }

    function _isAssetWhitelisted(address _asset) internal view returns(bool) {
        return PRICE_AGGREGATOR.isAssetSupported(_asset) && whitelistedAssets.contains(_asset);
    }

    /**
     * @notice returns the price aggregator contract
     */
    function getPriceAggregator() external view returns (IPriceAggregator) {
        return PRICE_AGGREGATOR;
    }

    /**
     * @notice returns all whitelisted assets
     * @return address array containing all whitelisted assets
     */
    function getWhitelistedAssets() external view returns (address[] memory) {
        return whitelistedAssets.values();
    }

    /**
     * @notice returns all denomination assets
     * @return address array containing all denomination assets
     */
    function getDenominationAssets() external view returns (address[] memory) {
        return denominationAssets.values();
    }

    /**
     * @dev cuts down on bytecode size
     */
    function _validateArray(address[] calldata _array) internal view {
        if (_array.length == 0) revert Errors.EmptyArray();
    }

    /**
     * @dev cuts down on bytecode size
     */
    function _validateAsset(address _asset) internal view {
        if (_asset == address(0)) revert Errors.ZeroAddress();
        if (!(PRICE_AGGREGATOR.isAssetSupported(_asset))) revert Errors.AssetNotSupported();
    }

    /**
     * @dev overridden authorize upgrade...
     */
    function _authorizeUpgrade(address) internal virtual override onlyHubOwner {}
}
