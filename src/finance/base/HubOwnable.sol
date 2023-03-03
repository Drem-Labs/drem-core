// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {HubAware} from "./HubAware.sol";

error NotHubOwner();

abstract contract HubOwnable is HubAware {
    constructor(address _dremHub) HubAware(_dremHub){}

    modifier onlyHubOwner() {
        _validateMsgSenderHubOwner();
        _;
    }

    function _validateMsgSenderHubOwner() internal {
        if (msg.sender != DREM_HUB.owner()) revert NotHubOwner();
    }
    
}