// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {IDremHub} from "../src/finance/interfaces/IDremHub.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DremHubHelper is Test {

    DremHub dremHub;
    address dremHubImplementation;

    function setUp() virtual public {
       dremHubImplementation = address(new DremHub()); 
       bytes memory _emptyBytes;
       dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, _emptyBytes)));
    }
}

contract Initializer is DremHubHelper {
    function setUp() override public {
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
    function setUp() override public {
        DremHubHelper.setUp();
        dremHub.init();
    }

    function test_setGlobalTrading() public {
        dremHub.setGlobalTrading(true);
    }

    function test_setGlobalTrading_revert_nonOwner() public {
        address _randomAddress = address(0x67);
        vm.startPrank(_randomAddress);

        vm.expectRevert("Ownable: caller is not the owner");
        dremHub.setGlobalTrading(true);

        vm.stopPrank();
    }

    function test_setGlobalTrading_revert_invalidParam() public {
        vm.expectRevert(IDremHub.InvalidParam.selector);
        dremHub.setGlobalTrading(false);
    }
}