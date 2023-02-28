// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {DataTypes} from "../src/finance/libraries/DataTypes.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {Events} from "../src/finance/libraries/Events.sol";
import {Helper} from "./reference/Helper.sol";
import {IDremHub} from "../src/finance/interfaces/IDremHub.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract DremHubHelper is Test, Helper {
    DremHub dremHub;
    address dremHubImplementation;

    function setUp() public virtual {
        dremHubImplementation = address(new DremHub());
        bytes memory _emptyBytes;
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, _emptyBytes)));
    }
}

contract Initializer is DremHubHelper {
    function setUp() public override {
        DremHubHelper.setUp();
    }

    function test_init_revertIf_implementation() public {
        DremHub _implementation = DremHub(dremHubImplementation);
        vm.expectRevert("Initializable: contract is already initialized");
        _implementation.init();
    }

    function test_init() public {
        dremHub.init();

        vm.expectRevert("Initializable: contract is already initialized");
        dremHub.init();

        assertEq(dremHub.owner(), address(this));
    }
}

contract Admin is DremHubHelper {
    function setUp() public override {
        DremHubHelper.setUp();
        dremHub.init();
    }

    function test_setGlobalTrading() public {

        vm.expectEmit(true, true, true, true);
        emit Events.GlobalTradingSet(true);

        dremHub.setGlobalTrading(true);
    }

    function test_SetGlobalTrading_RevertIf_NonOwner() public {
        address _randomAddress = address(0x67);
        vm.startPrank(_randomAddress);

        vm.expectRevert("Ownable: caller is not the owner");
        dremHub.setGlobalTrading(true);

        vm.stopPrank();
    }

    function test_AddWhitelistedStep_AnyCall() public {
        DataTypes.StepInfo memory _step = DataTypes.StepInfo({
            interactionAddress: USDC_ADDRESS,
            functionSelector: ERC20.transfer.selector
        });

        bytes memory _encodedArgs = bytes("DremHub.ANY_CALL");

        vm.expectEmit(true, true, true, true);
        emit Events.WhitelistedStepAdded(_step.interactionAddress, _step.functionSelector, _encodedArgs);

        dremHub.addWhitelistedStep(_step, _encodedArgs);

        // Test if the ANY_CALL encoded arg is true
        assertTrue(dremHub.isStepWhitelisted(_step, _encodedArgs));

        // Test other encoded args
        address to =  address(0x67);
        uint256 amount = 10 ** 6;

        bytes memory _otherEncodedArgs = abi.encode(to, amount);
        assertTrue(dremHub.isStepWhitelisted(_step, _otherEncodedArgs));
    }
    
    function test_AddWhitelistedStep_NonAnyCall() public {
        DataTypes.StepInfo memory _step = DataTypes.StepInfo({
            interactionAddress: USDC_ADDRESS,
            functionSelector: ERC20.transfer.selector
        }); 

        // Arguments
        address to =  address(0x67);
        uint256 amount = 10 ** 6;

        bytes memory _encodedArgs = abi.encode(to, amount);

        vm.expectEmit(true, true, true, true);
        emit Events.WhitelistedStepAdded(_step.interactionAddress, _step.functionSelector, _encodedArgs);

        dremHub.addWhitelistedStep(_step, _encodedArgs);

        assertTrue(dremHub.isStepWhitelisted(_step, _encodedArgs)); 
        assertFalse(dremHub.isStepWhitelisted(_step, ANY_CALL));
    }

    function test_RemoveWhitelistedStep() public {
        DataTypes.StepInfo memory _step = DataTypes.StepInfo({
            interactionAddress: USDC_ADDRESS,
            functionSelector: ERC20.transfer.selector
        });
        bytes memory _encodedArgs = bytes("DremHub.ANY_CALL");

        dremHub.addWhitelistedStep(_step, _encodedArgs);

        // Test if the ANY_CALL encoded arg is true
        assertTrue(dremHub.isStepWhitelisted(_step, _encodedArgs));

        vm.expectEmit(true,true,true,true);
        emit Events.WhitelistedStepRemoved(_step.interactionAddress, _step.functionSelector, _encodedArgs);

        dremHub.removeWhitelistedStep(_step, _encodedArgs);

        assertFalse(dremHub.isStepWhitelisted(_step, _encodedArgs));
    }

    function test_AddWhitelistedStep_RevertIf_InvalidInteractionAddress() public {
        DataTypes.StepInfo memory _step = DataTypes.StepInfo({
            interactionAddress: address(0),
            functionSelector: ERC20.transfer.selector
        });
        bytes memory _encodedArgs = bytes("DremHub.ANY_CALL");

        vm.expectRevert(IDremHub.InvalidStep.selector);
        dremHub.addWhitelistedStep(_step, _encodedArgs);
    }

    function test_AddWhitelistedStep_RevertIf_InvalidFunctionSelector() public {
        DataTypes.StepInfo memory _step = DataTypes.StepInfo({
            interactionAddress: USDC_ADDRESS,
            functionSelector: bytes4(0)
        });
        bytes memory _encodedArgs = bytes("DremHub.ANY_CALL");

        vm.expectRevert(IDremHub.InvalidStep.selector);
        dremHub.addWhitelistedStep(_step, _encodedArgs);
    }

    function test_RemoveWhitelistedStep_RevertIf_InvalidInteractionAddress() public {
        DataTypes.StepInfo memory _step = DataTypes.StepInfo({
            interactionAddress: address(0),
            functionSelector: ERC20.transfer.selector
        });
        bytes memory _encodedArgs = bytes("DremHub.ANY_CALL");

        vm.expectRevert(IDremHub.InvalidStep.selector);
        dremHub.removeWhitelistedStep(_step, _encodedArgs);
    }

    function test_RemoveWhitelistedStep_RevertIf_InvalidFunctionSelector() public {
        DataTypes.StepInfo memory _step = DataTypes.StepInfo({
            interactionAddress: USDC_ADDRESS,
            functionSelector: bytes4(0)
        });
        bytes memory _encodedArgs = bytes("DremHub.ANY_CALL");

        vm.expectRevert(IDremHub.InvalidStep.selector);
        dremHub.addWhitelistedStep(_step, _encodedArgs);
    }

    function test_SetVaultDeployer_RevertIf_AdressIsEOA() public {
        address _eoaAddress = address(0x1);

        vm.expectRevert(IDremHub.InvalidVaultDeployerAddress.selector);
        dremHub.setVaultDeployer(_eoaAddress);
    }

    function test_SetVaultDeployer() public {
        dremHub.setVaultDeployer(address(this));
    }

}

contract ExternalFunctions is DremHubHelper {
    function setUp() override public {
        DremHubHelper.setUp();
        dremHub.init();
    }

    function test_DremHubTransferHook_RevertIf_TradingNotAllowed() public {
        dremHub.setGlobalTrading(false);

        vm.expectRevert(IDremHub.TradingDisabled.selector);
        dremHub.dremHubBeforeTransferHook();
    }

    function test_DremHubTransferHook_RevertIf_TradingAllowed() public {
        dremHub.setGlobalTrading(true);
        dremHub.dremHubBeforeTransferHook();
    }

}
