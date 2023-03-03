
// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IDremHub} from "../interfaces/IDremHub.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {HubAware} from "./HubAware.sol";

error ProtocolPausedOrFrozen();
error ProtocolFrozen();

abstract contract StateAware is HubAware {
    constructor(address _dremHub) HubAware(_dremHub) {}

    modifier pausable() {
        _validateNotPausedOrFrozen();
        _;
    }

    modifier freezable() {
        _validateNotFrozen();
        _;
    }

    function _validateNotPausedOrFrozen() internal view {
        if (DREM_HUB.getProtocolState() > DataTypes.ProtocolState.Unpaused) revert ProtocolPausedOrFrozen();
    }

    function _validateNotFrozen() internal view {
        if (DREM_HUB.getProtocolState() == DataTypes.ProtocolState.Frozen) revert ProtocolFrozen(); 
    }
}