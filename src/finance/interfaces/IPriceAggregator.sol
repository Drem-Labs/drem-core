// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IPriceAggregator{

    function getAssetPrice(address denominationAsset, address outputAsset) external view returns(uint256);

}