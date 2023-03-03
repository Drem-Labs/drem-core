// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IStep} from "./IStep.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";


// this is really where any useful modifiers and universal data goes
abstract contract BaseStep is IStep {
    // keep track of the hub, can be mutable, but you need to check the owner of the previous one
    address public hub;

    // set the state (this will be checked at each function with an or statement, not sure a modifier is necessary here)
    // this state should be checked on init, wind, and unwind (too complex for checking on validate)
    DataTypes.StepState public state;

    // set the hub owner in the constructor, that's all
    constructor (address _hub) {
        _setHub(_hub);
    }

    // modifier for the hub owner
    modifier onlyHubOwner() {
        if (msg.sender != IOwnable(hub).owner()) revert NotHubOwner();
    }

    // set the state (does not matter if the step is ownable, should default to the hub owner)
    function setState(DataTypes.StepState _state) external onlyHubOwner {
        // check that the caller owns the DremHub (all power should default here, as the MS will be secure
        // set the state
        state = _state;
    }

    // set the hub owner (callable)
    function setHub(address _hub) external onlyHubOwner {
        _setHub(_hub);
    }

    // set the hub owner (internal)
    function _setHub(address _hub) internal {
        hub = _hub;
    }
}
