// SPDX-License-Identifier: MIT

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DataTypes} from "../../src/finance/libraries/DataTypes.sol";
import {Fork} from "../reference/Fork.sol";
import {DremHub} from "../../src/finance/core/DremHub.sol";
import {Vault} from "../../src/finance/core/vault/Vault.sol";
import {TransferStep} from "../../src/finance/steps/extensions/Transfer/TransferStep.sol";
import {TransferLib} from "../../src/finance/steps/extensions/Transfer/TransferLib.sol";
import {Helper} from "../reference/Helper.sol";

// TransferStep harness for testing internal functions
contract TransferStepHarness is TransferStep {
    constructor(address dremHub, address feeController) TransferStep(dremHub, feeController) {}

    // split funds

    // send funds

    // set fee controller
}

// fork
contract TransferStepHelper is Helper, Fork {
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

        // make the step info
        DataTypes.StepInfo memory stepInfo = DataTypes.StepInfo({interactionAddress: address(transferStep)});

        // add the transfer step to the hub
        dremHub.addWhitelistedStep(stepInfo);
    }
}

contract InternalFunctions is TransferStepHelper {
    TransferStepHarness transferStepHarness;

    function setUp() public virtual override {
        TransferStepHelper.setUp();

        transferStepHarness = new TransferStepHarness(address(dremHub), address(0));
    }

    // test splitting funds

    // test sending funds

    // test setting fee controller
}
