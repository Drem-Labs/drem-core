// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IDremHub} from "../interfaces/IDremHub.sol";
import {DremHub} from "../core/DremHub.sol";
import {Errors} from "../libraries/Errors.sol";

abstract contract HubAware {
    DremHub immutable DREM_HUB;

    constructor(address _hub) {
        if (_hub == address(0)) revert Errors.ZeroAddress();
        DREM_HUB = DremHub(_hub);
    }
}
