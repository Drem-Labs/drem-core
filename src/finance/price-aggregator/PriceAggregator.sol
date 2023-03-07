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

    uint256 private constant CHAINLINK_DECIMALS = 8;

    // 'Heartbeats' for Chainlink's Polygon USD Aggregators are 30 seconds
    // 'Heartbeats' for Chainlink's Polygon ETH Aggregators are 24 hours
    // Reference:
    //  - https://docs.chain.link/data-feeds#check-the-timestamp-of-the-latest-answer
    //  - https://data.chain.link/polygon/mainnet/crypto-usd
    uint256 public constant STALE_USD_PRICE_LIMIT = 30;
    uint256 public constant STALE_ETH_PRICE_LIMIT = 24 hours;

    // Reference: https://polygonscan.com/address/0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    constructor (address _dremHub) HubOwnable(_dremHub) {}

    mapping(address => DataTypes.SupportedAssetInfo) private assetToInfo;
    AggregatorV3Interface private maticToUSDAggregator;
    AggregatorV3Interface private ethToUSDAggregator;

    function setMaticToUSDAggregator(AggregatorV3Interface _maticToUSDAggregator) external onlyHubOwner {
        if (address(_maticToUSDAggregator) == address(0)) revert Errors.ZeroAddress();

        maticToUSDAggregator = _maticToUSDAggregator;
        emit Events.MaticToUSDAggregatorSet(_maticToUSDAggregator);
    }

    function setEthToUSDAggregator(AggregatorV3Interface _ethToUSDAggregator) external onlyHubOwner {
        if (address(_ethToUSDAggregator) == address(0)) revert Errors.ZeroAddress();

        ethToUSDAggregator = _ethToUSDAggregator;
        emit Events.EthToUSDAggregatorSet(_ethToUSDAggregator);
    }

    function addSupportedAsset(address _asset, AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset) external onlyHubOwner {
        if(_asset == address(0) || address(_aggregator) == address(0)) revert Errors.ZeroAddress();

        _validateAggregator(_aggregator, _rateAsset);

        uint256 _units = 10 ** (ERC20(_asset).decimals());

        assetToInfo[_asset] = DataTypes.SupportedAssetInfo({
            aggregator: _aggregator,
            rateAsset: _rateAsset,
            units: _units
        });

        emit Events.SupportedAssetAdded(_asset, _aggregator, _rateAsset);
    }

    /**
     * PROBLEM: CANT HAVE BOTH ETH AND USD AGGREGATOR FOR ASSETS under current implementation
     * Should always use USDC... Faster heartbeat...
     */

    function removeSupportedAsset(address _asset) external onlyHubOwner {
        if (_asset == address(0)) revert Errors.ZeroAddress();

        DataTypes.SupportedAssetInfo memory _info = assetToInfo[_asset];

        delete assetToInfo[_asset];

        emit Events.SupportedAssetRemoved(_asset, _info.aggregator, _info.rateAsset);
    }


    function getAssetPrice(address denominationAsset, address outputAsset) external view returns(uint256) {

    }

    function getEthToUSDAggregator() external view returns (AggregatorV3Interface) {
        return ethToUSDAggregator;
    }

    function getMaticToUSDAggregator() external view returns (AggregatorV3Interface) {
        return maticToUSDAggregator;
    }

    function getSupportedAssetInfo(address _asset) external view returns (DataTypes.SupportedAssetInfo memory) {
        return assetToInfo[_asset];
    }

    function isAssetSupported(address _asset) external view returns(bool) {
        return address(assetToInfo[_asset].aggregator) != address(0);
    }

    function _calcUSDtoEthConversion() internal view {

    }

    function _calcEthToUSDConversion() internal view {

    }

    function _calcConversionSameRateAsset() internal view {

    }

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

        // Case B: Input asset has a rate asset of USD, Output asset has a rate asset of ETH
        if (inputInfo.rateAsset == DataTypes.RateAsset.USD) {
            uint256 unitAdjustedAmount = (_amount * outputInfo.units) / inputInfo.units;
            return (unitAdjustedAmount * inputRate * CHAINLINK_DECIMALS) / (outputRate * ethToUSDRate);
        }
        // Case C: Input asset has a rate of ETH, Output asset has a rate asset of USD
        else {
            uint256 unitAdjustedAmount = (_amount * outputInfo.units) / inputInfo.units;
            return (unitAdjustedAmount * inputRate * ethToUSDRate) / (outputRate * CHAINLINK_DECIMALS);
        }
    }

    function _getLatestRate(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset) internal view returns (uint256) {
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(_aggregator).latestRoundData();
        _validateRate(_answer, _updatedAt, _rateAsset);
        return uint256(_answer);
    }

    function _validateAggregator(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset) internal view {
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(_aggregator).latestRoundData();

        _validateRate(_answer, _updatedAt, _rateAsset);
    }

    // Unsure if I should split this into three different internal functions
    function _validateRate(int256 _answer, uint256 _updatedAt, DataTypes.RateAsset _rateAsset) internal view {
        if (!(_answer > 0)) revert Errors.InvalidAggregatorRate();

        if(_rateAsset == DataTypes.RateAsset.USD) {
            if( (block.timestamp - _updatedAt) > STALE_USD_PRICE_LIMIT) revert Errors.StaleUSDRate();
        }
        // _rateAsset == DataTypes.RateAsset.ETH
        else {
            if((block.timestamp - _updatedAt) > STALE_ETH_PRICE_LIMIT) revert Errors.StaleEthRate();
        }
    }
 }
