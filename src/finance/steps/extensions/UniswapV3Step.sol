// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {BaseStep} from "../BaseStep.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";

/**
 * Step actions include:
 * Action 1: Swap
 * Action 2: Add Liquidity
 * Action 3: Remove Liquidity
 */

// abstract for now, as this is not a full contract
abstract contract UniswapV3StepAdapter is BaseStep {
    function init(uint256 _argIndex, bytes calldata _fixedArgs) external {}

    function wind(uint256 _argIndex, bytes memory _variableArgs) external {}

    function unwind(uint256 _argIndex, bytes memory _variableArgs) external {}

    function _swap() internal {}

    function _addLiquidity() internal {}

    function _removeLiquidity() internal {}
}
