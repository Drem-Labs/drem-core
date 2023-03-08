// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IStep} from "./IStep.sol";
import {HubOwnable} from "../base/HubOwnable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

// this is really where any useful modifiers and universal data goes
abstract contract BaseStep is IStep, HubOwnable {
    // set the state (this will be checked at each function with an or statement, not sure a modifier is necessary here)
    // this state should be checked on init, wind, and unwind (too complex for checking on validate)
    DataTypes.StepState public state;

    constructor(address _dremHub) HubOwnable(_dremHub) {}

    // set the state (does not matter if the step is ownable, should default to the hub owner)
    function setState(DataTypes.StepState _state) external onlyHubOwner {
        // check that the caller owns the DremHub (all power should default here, as the MS will be secure
        // set the state
        state = _state;
    }
}
