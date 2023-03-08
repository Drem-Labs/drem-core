// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {StateAware} from "../base/StateAware.sol";
import {Vault} from "./vault/Vault.sol";

contract VaultDeployer is StateAware, UUPSUpgradeable {

    Vault vaultImplementation;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    constructor(address _dremHub) StateAware(_dremHub) {
        vaultImplementation = new Vault(_dremHub);
    }

    function init() external initializer {
        vaultImplementation = new Vault(DREM_HUB);
    }

    function createVault() external {}

}
