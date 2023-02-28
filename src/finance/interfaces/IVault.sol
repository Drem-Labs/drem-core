// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IVault is IERC20 {

    // steps and assets
    function steps() external view returns(DataTypes.StepInfo[] memory);

    // share accounting
    function mintShares(uint256 shareAmount) external;
    function burnShares(uint256 shareAmount) external;

    // safegaurding funds
    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external;
}
