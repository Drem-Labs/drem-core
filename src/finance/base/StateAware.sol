
// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IDremHub} from "../interfaces/IDremHub.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

error ProtocolPausedOrFrozen();
error ProtocolFrozen();

abstract contract StateAware {

    IDremHub immutable DREM_HUB;
    constructor(address _hub ) {
        DREM_HUB = IDremHub(_hub);
    }

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