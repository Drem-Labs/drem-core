// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DataTypes} from "../src/finance/libraries/DataTypes.sol";
import {DremERC20} from "../src/finance/base/DremERC20.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {HubAware} from "../src/finance/base/HubAware.sol";
import {HubOwnable} from "../src/finance/base/HubOwnable.sol";
import {IDremHub} from "../src/finance/interfaces/IDremHub.sol";

contract DremERC20Harness is DremERC20 {
    constructor(address dremHub) DremERC20(dremHub){}
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

}

contract DremERC20Test is Test {

    DremERC20Harness dremERC20;
    DremHub dremHub;
    address alice = address(0x67);
    function setUp() public {
        address dremHubImplementation = address(new DremHub());

        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));
        dremHub.init();
        
        dremERC20 = new DremERC20Harness(address(dremHub));

        dremERC20.mint(address(this), 1 ether);

        dremHub.setGlobalTrading(true);
    }

    function test_Transfer_GlobalStateUnpausedAndTradingAllowed() public {
        dremERC20.transfer(alice, 1_000);
    }

    function test_Transfer_GlobalStatePaused() public {
        dremHub.setProtocolState(DataTypes.ProtocolState.Paused);
        dremERC20.transfer(alice, 1_000); 
    }

    function test_Transfer_GlobalStateFrozen() public {
        dremHub.setProtocolState(DataTypes.ProtocolState.Frozen);
        vm.expectRevert(IDremHub.TradingDisabled.selector);
        dremERC20.transfer(alice, 1_000); 
    }

    function test_Transfer_TradingNotAllowed() public {
        dremHub.setGlobalTrading(false);
        vm.expectRevert(IDremHub.TradingDisabled.selector);
        dremERC20.transfer(alice, 1_000); 
    }

    function test_Mint_TradingNotAllowed() public {
        dremHub.setGlobalTrading(false);
        dremERC20.mint(address(this), 1 ether);
    }

    function test_Burn_TradingNotAllowed() public {
        dremHub.setGlobalTrading(false);
        dremERC20.burn(1 ether);
    }
}

contract HubAwareHarness is HubAware {
    constructor(address _dremHub) HubAware(_dremHub) {}
    function getDremHub() external returns (address){
        return address(DREM_HUB);
    }
}

contract HubAwareTest is Test {
    HubAwareHarness hubAwareHarness;

    function testHubAware() public {
        address randomAddress = address(0x67);
        hubAwareHarness = new HubAwareHarness(randomAddress);
        assertEq(hubAwareHarness.getDremHub(), randomAddress);
    }
}