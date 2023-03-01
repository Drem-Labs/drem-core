// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {StateAware} from "./StateAware.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

abstract contract DremERC20 is ERC20Upgradeable, StateAware {

    constructor (address _dremHub) StateAware(_dremHub){}

    /**
     * Three different transfer cases:
     * Case 1. Minting
     * Case 2. Burning
     * Case 3. Transfers
     * Minting and burning should be possible when global transfers are turned off
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (from != address(0) && to != address(0)) DREM_HUB.dremHubBeforeTransferHook();
    }
}