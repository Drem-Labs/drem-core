// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IStep} from "../../interfaces/IStep.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";

/**
 * Step actions include: 
 * Action 1: Swap
 * Action 2: Add Liquidity
 * Action 3: Remove Liquidity
 */

contract UniswapV3StepAdapter is IStep {
    function processStep(DataTypes.StepInfo calldata, bytes calldata) external {

    }

    function unwindStep(DataTypes.StepInfo calldata, bytes calldata) external {

    }

    function _swap() internal {}

    function _addLiquidity() internal {}

    function _removeLiquidity() internal {}
}
