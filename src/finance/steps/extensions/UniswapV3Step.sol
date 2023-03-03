// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IStep} from "..//IStep.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";

/**
 * Step actions include: 
 * Action 1: Swap
 * Action 2: Add Liquidity
 * Action 3: Remove Liquidity
 */

contract UniswapV3StepAdapter is IStep {

    function init(bytes calldata) external {}

    function wind(bytes calldata _encodedArgs) external {
        // (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));
        (uint256 actionId, bytes memory args) = abi.decode(_encodedArgs, (uint256, bytes));

    }

    function unwind(bytes calldata) external {

    }

    function _swap() internal {}

    function _addLiquidity() internal {}

    function _removeLiquidity() internal {}
}
