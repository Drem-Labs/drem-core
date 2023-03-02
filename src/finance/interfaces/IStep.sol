// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IStep {
    function processStep(DataTypes.StepInfo calldata, bytes calldata) external;

    function unwindStep(DataTypes.StepInfo calldata, bytes calldata) external;
}
