// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IFeeController {
    // getters for calculation
    function decimals() external returns(uint256);
    function fees(address vault) returns(uint256);

    // make calculation easy (all in one place)
    function calculateFee(uint256 fundsIn, uint256 vault);
}
