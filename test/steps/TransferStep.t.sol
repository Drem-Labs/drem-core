// SPDX-License-Identifier: MIT

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Fork} from "../reference/Fork.sol";
import {DremHub} from "../../src/finance/core/DremHub.sol";
import {Vault} from "../../src/finance/core/vault/Vault.sol";
import {TransferStep} from "../../src/finance/steps/extensions/Transfer/TransferStep.sol";
import {TransferLib} from "../../src/finance/steps/extensions/Transfer/TransferLib.sol";

// TransferStep harness for testing internal functions
contract TransferStepHarness is TransferStep {
    constructor(address dremHub, address feeController) TransferStep(dremHub, feeController) {}
}

// fork
contract TransferStepHelper is Fork {
    // hub
    DremHub dremHub;
    address dremHubImplementation;

    // vault
    Vault vault;

    function setUp() public virtual override {
        // fork polygon
        Fork.setUp();

        // deploy the hub
        dremHubImplementation = address(new DremHub());
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));
        dremHub.init();

        // set the fee controller --> TO BE CREATED

        // deploy the transfer step
        TransferStep transferStep = new TransferStep(address(dremHub), address(0));

        // add the transfer step to the hub

        // deploy a vault
        vault = new Vault(address(dremHub));

        // add the transfer step to the vault
    }
}

contract Admin is TransferStepHelper {
    address Vault;

    function setUp() public virtual override {
        TransferStepHelper.setUp();

        // deploye a vault to test with
    }
}
