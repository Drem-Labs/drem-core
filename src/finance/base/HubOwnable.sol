// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Errors} from "../libraries/Errors.sol";
import {HubAware} from "./HubAware.sol";

abstract contract HubOwnable is HubAware {
    constructor(address _dremHub) HubAware(_dremHub) {}

    modifier onlyHubOwner() {
        _validateMsgSenderHubOwner();
        _;
    }

    function _validateMsgSenderHubOwner() internal view {
        if (msg.sender != DREM_HUB.owner()) revert Errors.NotHubOwner();
    }
}
