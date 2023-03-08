// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
interface IPriceAggregator{
    ////////////////////
    ///     Admin    ///
    ////////////////////
    function addSupportedAsset(address, AggregatorV3Interface, DataTypes.RateAsset) external; 
    function removeSupportedAsset(address) external;
    function setEthToUSDAggregator(AggregatorV3Interface) external;

    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////
    function convertAsset(uint256, address, address) external view returns(uint256);
    function isAssetSupported(address) external view returns(bool);
    function getEthToUSDAggregator() external view returns (AggregatorV3Interface);
    function getSupportedAssetInfo(address) external view returns (DataTypes.SupportedAssetInfo memory);
}