
// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IDremHub} from "../interfaces/IDremHub.sol";
import {DremHub} from "../core/DremHub.sol";

abstract contract HubAware {

    DremHub immutable DREM_HUB;
    constructor(address _hub ) {
        DREM_HUB = DremHub(_hub);
    }
}