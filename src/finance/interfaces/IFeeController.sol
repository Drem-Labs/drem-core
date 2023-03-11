// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IFeeController {
    // getters for calculation
    function decimals() external returns (uint256);
    function fees(address vault) external returns (uint256);

    // getter for the controller
    function controller() external returns (address);

    // make calculation easy (all in one place)
    function calculateFee(uint256 fundsIn, address vault) external returns (uint256);
}
