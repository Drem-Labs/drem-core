// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IVault is IERC20Upgradeable {

    error InvalidNumberOfSteps();
    error InvalidStepsLength();
    error InvalidAccessor();
    error StepsAndArgsNotSameLength();
    error StepNotWhitelisted();
    error CallFailed();

    // steps and assets
    function getSteps() external view returns (DataTypes.StepInfo[] memory);

    // share accounting
    function mintShares(uint256 shareAmount, address to) external;
    function burnShares(uint256 shareAmount, address to) external;

    // executing transactions (for steps to access)
    function execute(address to, bytes calldata data) external returns(bytes memory);

    // safegaurding funds
    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external;
}
