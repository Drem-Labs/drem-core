// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {HubOwnable} from "./HubOwnable.sol";
import {IDremHub} from "../interfaces/IDremHub.sol";

abstract contract StateAware is HubOwnable {
    constructor(address _dremHub) HubOwnable(_dremHub) {}

    modifier pausable() {
        _validateNotPausedOrFrozen();
        _;
    }

    modifier freezable() {
        _validateNotFrozen();
        _;
    }

    function _validateNotPausedOrFrozen() internal view {
        if (DREM_HUB.getProtocolState() > DataTypes.ProtocolState.Unpaused) revert Errors.ProtocolPausedOrFrozen();
    }

    function _validateNotFrozen() internal view {
        if (DREM_HUB.getProtocolState() == DataTypes.ProtocolState.Frozen) revert Errors.ProtocolFrozen();
    }
}
