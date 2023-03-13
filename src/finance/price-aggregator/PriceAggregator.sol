// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
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
    // Reference: https://polygonscan.com/address/0x327e23A4855b6F663a28c5161541d69Af8973302#readContract#F8
    uint256 private constant CHAINLINK_ETH_UNITS = 1e18;

    // 'Heartbeats' for Chainlink's Polygon USD Aggregators are 30 seconds
    // 'Heartbeats' for Chainlink's Polygon ETH Aggregators are 24 hours
    // Reference:
    //  - https://docs.chain.link/data-feeds#check-the-timestamp-of-the-latest-answer
    //  - https://data.chain.link/polygon/mainnet/crypto-usd
    uint256 public constant STALE_USD_PRICE_LIMIT = 30;
    uint256 public constant STALE_ETH_PRICE_LIMIT = 24 hours;

    // Reference: https://polygonscan.com/address/0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    mapping(address => DataTypes.SupportedAssetInfo) private assetToInfo;
    AggregatorV3Interface private ethToUSDAggregator;

    constructor(address _dremHub, address _ethToUSDAggregator) HubOwnable(_dremHub) {
        _validateAggregator(AggregatorV3Interface(_ethToUSDAggregator), DataTypes.RateAsset.USD);
        ethToUSDAggregator = AggregatorV3Interface(_ethToUSDAggregator);
    }

    ////////////////////
    ///     Admin    ///
    ////////////////////

    /**
     * @dev Sets the ETH to USD Price Feed
     * @param _ethToUSDAggregator the new value for the ETH to USD price feed
     */
    function setEthToUSDAggregator(AggregatorV3Interface _ethToUSDAggregator) external onlyHubOwner {
        if (address(_ethToUSDAggregator) == address(0)) revert Errors.ZeroAddress();
        _validateAggregator(_ethToUSDAggregator, DataTypes.RateAsset.USD);
        ethToUSDAggregator = _ethToUSDAggregator;
        emit Events.EthToUSDAggregatorSet(_ethToUSDAggregator);
    }

    function addSupportedAssets(
        address[] calldata _assets,
        AggregatorV3Interface[] calldata _aggregators,
        DataTypes.RateAsset[] calldata _rateAssets
    ) external onlyHubOwner {
        uint256 len = _assets.length;
        if (len == 0) revert Errors.EmptyArray();
        if (len != _aggregators.length || len != _rateAssets.length) revert Errors.InvalidAssetArrays();

        for (uint256 i; i < len;) {
            _addSupportedAsset(_assets[i], _aggregators[i], _rateAssets[i]);
            unchecked {
                ++i;
            }
        }
    }

    function removeSupportedAssets(address[] calldata _assets) external onlyHubOwner {
        uint256 len = _assets.length;
        if (len == 0) revert Errors.EmptyArray();

        for (uint256 i; i < len;) {
            _removeSupportedAsset(_assets[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Adds a supported asset
     * @param _asset the asset to add
     * @param _aggregator the asset's price aggregator
     * @param _rateAsset the rate asset to use
     */
    function _addSupportedAsset(address _asset, AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset)
        internal
    {
        if (_asset == address(0) || address(_aggregator) == address(0)) revert Errors.ZeroAddress();

        _validateAggregator(_aggregator, _rateAsset);

        uint256 _units = 10 ** (ERC20(_asset).decimals());

        assetToInfo[_asset] =
            DataTypes.SupportedAssetInfo({aggregator: _aggregator, rateAsset: _rateAsset, units: _units});

        emit Events.SupportedAssetAdded(_asset, _aggregator, _rateAsset);
    }

    /**
     * @dev Removes a supported asset
     * @param _asset the asset to remove
     */
    function _removeSupportedAsset(address _asset) internal {
        if (_asset == address(0)) revert Errors.ZeroAddress();

        DataTypes.SupportedAssetInfo memory _info = assetToInfo[_asset];

        delete assetToInfo[_asset];

        emit Events.SupportedAssetRemoved(_asset, _info.aggregator, _info.rateAsset);
    }

    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Converts an amount of an input asset into an output asset
     * @param _inputAmounts the amounts of the input assets to convert
     * @param _inputAssets the input assets
     * @param _outputAsset the output asset
     * @return the output amount
     */
    function convertAssets(uint256[] calldata _inputAmounts, address[] calldata _inputAssets, address _outputAsset)
        external
        view
        returns (uint256)
    {
        if (_inputAmounts.length != _inputAssets.length) revert Errors.InvalidInputArrays();
        _validateAsset(_outputAsset);

        uint256 totalConversion;

        for (uint256 i; i < _inputAssets.length;) {
            _validateAsset(_inputAssets[i]);

            uint256 conversion = _convert(_inputAmounts[i], _inputAssets[i], _outputAsset);

            totalConversion = totalConversion + conversion;
            unchecked {
                ++i;
            }
        }

        if (totalConversion == 0) revert Errors.InvalidConversion();

        return totalConversion;
    }

    function convertStepPositionPrice() external view {}

    /**
     * @notice returns whether or not an asset is supported
     * @return bool
     */
    function isAssetSupported(address _asset) external view returns (bool) {
        return _isAssetSupported(_asset);
    }

    /**
     * @notice gets the ETH to USD price aggregator
     * @return the ETH to USD price aggregator
     */
    function getEthToUSDAggregator() external view returns (AggregatorV3Interface) {
        return ethToUSDAggregator;
    }

    /**
     * @notice gets the supported asset's info
     * @param _asset the asset to get the info for
     * @return the supported asset info
     */
    function getSupportedAssetInfo(address _asset) external view returns (DataTypes.SupportedAssetInfo memory) {
        return assetToInfo[_asset];
    }

    // Internal Functions
    /**
     * @dev calculates and returns the conversion of a '_amount' of the '_inputAsset' into the '_outputAsset'
     * The input rate and output rate will should the same number of decimals when using Chainlink
     * However, the units of each asset will be different.  Therefore, need to multiply the amount by the output asset units
     */
    function _convert(uint256 _amount, address _inputAsset, address _outputAsset) internal view returns (uint256) {
        DataTypes.SupportedAssetInfo memory inputInfo = assetToInfo[_inputAsset];
        DataTypes.SupportedAssetInfo memory outputInfo = assetToInfo[_outputAsset];

        uint256 inputRate = _getLatestRate(inputInfo.aggregator, inputInfo.rateAsset);
        uint256 outputRate = _getLatestRate(outputInfo.aggregator, outputInfo.rateAsset);

        // Case A: Both rate assets are the same
        if (inputInfo.rateAsset == outputInfo.rateAsset) {
            return (_amount * inputRate * outputInfo.units) / (outputRate * inputInfo.units);
        }

        uint256 ethToUSDRate = _getLatestRate(ethToUSDAggregator, DataTypes.RateAsset.USD);

        // Note: The arithmetic for cases B and C are split into two calculations to account for overflow

        // Note: Rounding errors can occurs for cases B and C
        // If the output units are small, such as 10^6, too small of an input may produce a rounding error
        // For example, take the overflow adjusted amount for Case B:
        // uint256 overflowAdjustment = (_amount * inputRate * outputInfo.units) / inputInfo.units;
        // Chainlink decimals = 10^8.  Assume the following:
        // - The inputRate is 10^8
        // - The output units are 10^6
        // - The input units are 10^18
        // Any value for amount below 10^4 will produce a rounding error

        // These edgecases will be extremely rare considering that 10^4 of the input token will be a very small dollar amount

        // Case B: Input asset has a rate asset of USD, Output asset has a rate asset of ETH
        if (inputInfo.rateAsset == DataTypes.RateAsset.USD) {
            uint256 overflowAdjustment = (_amount * inputRate * outputInfo.units) / inputInfo.units;
            return (overflowAdjustment * CHAINLINK_ETH_UNITS) / (outputRate * ethToUSDRate);
        }
        // Case C: Input asset has a rate of ETH, Output asset has a rate asset of USD
        else {
            uint256 overflowAdjustment = (_amount * inputRate * outputInfo.units) / inputInfo.units;
            return (overflowAdjustment * ethToUSDRate) / (outputRate * CHAINLINK_ETH_UNITS);
        }
    }

    function _getLatestRate(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset)
        internal
        view
        returns (uint256)
    {
        (, int256 _answer,, uint256 _updatedAt,) = AggregatorV3Interface(_aggregator).latestRoundData();
        _validateRate(_answer, _updatedAt, _rateAsset);
        return uint256(_answer);
    }

    function _validateAsset(address _asset) internal view {
        if (!(_isAssetSupported(_asset))) revert Errors.AssetNotSupported();
    }

    function _isAssetSupported(address _asset) internal view returns (bool) {
        return address(assetToInfo[_asset].aggregator) != address(0);
    }

    function _validateAggregator(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset) internal view {
        (, int256 _answer,, uint256 _updatedAt,) = AggregatorV3Interface(_aggregator).latestRoundData();
        _validateRate(_answer, _updatedAt, _rateAsset);
    }

    // Unsure if I should split this into three different internal functions
    function _validateRate(int256 _answer, uint256 _updatedAt, DataTypes.RateAsset _rateAsset) internal view {
        if (!(_answer > 0)) revert Errors.InvalidAggregatorRate();

        if (_rateAsset == DataTypes.RateAsset.USD) {
            if ((block.timestamp - _updatedAt) > STALE_USD_PRICE_LIMIT) revert Errors.StaleUSDRate();
        }
        // _rateAsset == DataTypes.RateAsset.ETH
        else {
            if ((block.timestamp - _updatedAt) > STALE_ETH_PRICE_LIMIT) revert Errors.StaleEthRate();
        }
    }
}
