// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IPriceAggregator {
    ////////////////////
    ///     Admin    ///
    ////////////////////
    function addSupportedAssets(address[] calldata, AggregatorV3Interface[] calldata, DataTypes.RateAsset[] calldata) external;
    function removeSupportedAssets(address[] calldata) external;
    function setEthToUSDAggregator(AggregatorV3Interface) external;

    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////
    function convertAssets(uint256[] calldata, address[] calldata, address) external view returns (uint256);
    function isAssetSupported(address) external view returns (bool);
    function getEthToUSDAggregator() external view returns (AggregatorV3Interface);
    function getSupportedAssetInfo(address) external view returns (DataTypes.SupportedAssetInfo memory);
}
