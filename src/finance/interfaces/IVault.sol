// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/DataTypes.sol";

interface IVault is IERC20 {

    // steps and assets
    function steps() external view returns(DataTypes.StepInfo[] memory);
    function addSteps(DataTypes.StepInfo[] calldata steps) external;
    function addTrackedAsset(address asset) external;
    function removeTrackedAsset(address asset) external;

    // share accounting
    function mintShares(uint256 shareAmount) external;
    function burnShares(uint256 shareAmount) external;

    // safegaurding funds
    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external;
}
