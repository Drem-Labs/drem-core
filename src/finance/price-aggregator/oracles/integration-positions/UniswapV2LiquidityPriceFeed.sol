// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

contract UniswapV2LiqudityPriceFeed {
    // Needs to verify that this is the owner of DremHub
    function addSupportedPoolTokens() external {}

    //
    function removeSupportedPoolTokens() external {}

    function calculatePositionValue(bytes calldata _encodedArgs) external {}

    function _validateTokenIsSupported(address) external {}
}
