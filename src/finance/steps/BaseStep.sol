// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IStep} from "./IStep.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

abstract contract BaseStep is IStep {
    // map the vault address and step to the fixed argument (allow this to be decoded in the derivative step contracts)
    mapping(address => mapping(uint256 => bytes)) public stepData;

    // keep track of the hub owner, can be mutable, but you need to check the owner of the previous hum
    address public hubOwner;

    // set the state (this will be checked at each function with an or statement, not sure a modifier is necessary here)
    // this state should be checked on init, wind, and unwind (too complex for checking on validate)
    DataTypes.StepState public state;

    // set the hub owner in the constructor, that's all
    constructor (address _hub) {
        _setHubOwner(_hub);
    }

    // modifier for the hub owner
    modifier onlyHubOwner() {
        if (msg.sender != hubOwner)
        {
            revert NotHubOwner();
        }
    }

    // set the state (does not matter if the step is ownable, should default to the hub owner)
    function setState(DataTypes.StepState _state) external onlyHubOwner {
        // check that the caller owns the DremHub (all power should default here, as the MS will be secure
        // set the state
        state = _state;
    }

    // set the hub owner (callable)

    // set the hub owner (internal)
}
