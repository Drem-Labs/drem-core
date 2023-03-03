// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DataTypes} from "../src/finance/libraries/DataTypes.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {Events} from "../src/finance/libraries/Events.sol";
import {Fork} from "./reference/Fork.sol";
import {IDremHub} from "../src/finance/interfaces/IDremHub.sol";
import {PriceAggregator} from "../src/finance/price-aggregator/PriceAggregator.sol";

/**
 * Fork inherits Helper
 */
contract PriceAggregatorHelper is Fork {
    DremHub dremHub;
    address dremHubImplementation;
    PriceAggregator priceAggregator;

    function setUp() public virtual override {
        Fork.setUp();
        dremHubImplementation = address(new DremHub());
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));
        dremHub.init();
        priceAggregator = new PriceAggregator(address(dremHub));
    }
}

contract Admin is PriceAggregatorHelper {
    function setUp() public virtual override {
        PriceAggregatorHelper.setUp();
    }

    function test_AddSupportedAsset() public {
        priceAggregator.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);

        DataTypes.SupportedAssetInfo memory _aaveInfo = priceAggregator.getSupportedAssetInfo(AAVE_ADDRESS);

        uint256 _aaveUnits = 10 ** (ERC20(AAVE_ADDRESS).decimals());

        assertEq(address(_aaveInfo.aggregator), address(AAVE_TO_USD_PRICE_FEED));
        assertEq(uint256(_aaveInfo.rateAsset), uint256(DataTypes.RateAsset.USD));
        assertEq(_aaveInfo.units, _aaveUnits);
        assertTrue(priceAggregator.isAssetSupported(AAVE_ADDRESS));
    }

    function test_AddSupportedAsset_RevertIf_NotHubOwner() public {
        // vm.startPrank(address(0x67));


        // vm.stopPrank();
    }

    function test_RemoveSupportedAsset() public {
        priceAggregator.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);
        priceAggregator.removeSupportedAsset(AAVE_ADDRESS);

        DataTypes.SupportedAssetInfo memory _aaveInfo = priceAggregator.getSupportedAssetInfo(AAVE_ADDRESS);

        assertEq(address(_aaveInfo.aggregator), address(0));
        assertEq(uint256(_aaveInfo.rateAsset), 0);
        assertEq(_aaveInfo.units, 0); 
    }

    function test_RemoveSupportedAsset_RevertIf_NotHubOwner() public {} 
} 
