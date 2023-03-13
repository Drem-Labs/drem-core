// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Errors} from "../src/finance/libraries/Errors.sol";
import {DataTypes} from "../src/finance/libraries/DataTypes.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {Helper} from "./reference/Helper.sol";
import {IVault} from "../src/finance/interfaces/IVault.sol";
import {Vault} from "../src/finance/core/vault/Vault.sol";

contract VaultHarness is Vault {
    constructor(address dremHub) Vault(dremHub) {}

    function addSteps(DataTypes.StepInfo[] calldata _steps) external {
        Vault._addSteps(_steps);
    }

    function validateStep(DataTypes.StepInfo calldata _step) external view {
        Vault._validateStep(_step);
    }

    function validateSteps(DataTypes.StepInfo[] calldata _steps) external view {
        Vault._validateSteps(_steps);
    }
}

contract VaultHelper is Test, Helper {
    DremHub dremHub;
    Vault vaultImplementation;

    function setUp() public virtual {
        address dremHubImplementation = address(new DremHub());
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));
        dremHub.init();
        vaultImplementation = new Vault(address(dremHub));
    }
}

contract ExternalFunctions is VaultHelper {
    function setUp() public override {
        VaultHelper.setUp();
    }

    function test_Init_Disabled() public {
        // vault.init();
    }

    function test_InitDisabled_Implementation() public {
        DataTypes.StepInfo[] memory _emptyStepInfo;
        bytes[] memory _emptyBytesArray;

        vm.expectRevert("Initializable: contract is already initialized");
        vaultImplementation.init(address(0), "", "", _emptyStepInfo, _emptyBytesArray);
    }
}

contract InternalFunctions is VaultHelper {
    VaultHarness vaultHarness;
    DataTypes.StepInfo[] steps;

    function setUp() public override {
        VaultHelper.setUp();
        vaultHarness = new VaultHarness(address(dremHub));
    }

    function test_addSteps() public {
        for (uint256 i; i < 5; ++i) {
            address _erc20 = address(new ERC20("", ""));

            DataTypes.StepInfo memory _step =
                DataTypes.StepInfo({interactionAddress: _erc20, functionSelector: ERC20.transfer.selector});
            bytes memory _encodedArgs = ANY_CALL;

            dremHub.addWhitelistedStep(_step);

            steps.push(_step);
        }

        vaultHarness.addSteps(steps);

        DataTypes.StepInfo[] memory queriedSteps = vaultHarness.getSteps();

        assertEq(queriedSteps.length, steps.length);

        for (uint256 i; i < queriedSteps.length; ++i) {
            assertEq(steps[i].functionSelector, queriedSteps[i].functionSelector);
            assertEq(steps[i].interactionAddress, queriedSteps[i].interactionAddress);
        }
    }

    function test_validateStep() public {
        address _erc20 = address(new ERC20("", ""));

        DataTypes.StepInfo memory _step =
            DataTypes.StepInfo({interactionAddress: _erc20, functionSelector: ERC20.transfer.selector});
        bytes memory _encodedArgs = ANY_CALL;

        dremHub.addWhitelistedStep(_step);

        vaultHarness.validateStep(_step);
    }

    function test_validateSteps_RevertIf_NoSteps() public {
        DataTypes.StepInfo[] memory _steps;
        bytes[] memory _encodedArgsPerStep;

        vm.expectRevert(Errors.InvalidNumberOfSteps.selector);
        vaultHarness.validateSteps(_steps);
    }

    function test_validateSteps_RevertIf_TooManySteps() public {
        // _encodedArgsPerStep actually doesn't matter to pass this test...
        bytes[] memory _encodedArgsPerStep;

        for (uint256 i; i < 11; ++i) {
            steps.push();
        }

        vm.expectRevert(Errors.InvalidNumberOfSteps.selector);
        vaultHarness.validateSteps(steps);

        assertEq(steps.length, 11);
    }
}
