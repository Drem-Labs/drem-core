// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetRegistry} from "../src/finance/asset-registry/AssetRegistry.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {Errors} from "../src/finance/libraries/Errors.sol";
import {Events} from "../src/finance/libraries/Events.sol";
import {Fork} from "./reference/Fork.sol";
import {PriceAggregator} from "../src/finance/price-aggregator/PriceAggregator.sol";

contract AssetRegistryHelper is Fork {
    DremHub DremHub;
    address dremHubImplementation;

    PriceAggregator priceAggregator;

    AssetRegistry assetRegistry;
    address assetRegistryImplementation;

    function setUp() public virtual {
        Fork.setUp();

        dremHubImplementation = address(new DremHub());
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));

        priceAggregator = new PriceAggregator(address(dremHub), address(ETH_TO_USD_PRICE_FEED));

        assetRegistryImplementation = address(new AssetRegistry());
        assetRegistry = AssetRegistry(address(new ERC1967Proxy(assetRegistryImplementation, new bytes(0))));
    }

    function test_setUp() public {
        _priceAggregator = assetRegistry.getPriceAggregator();
        assertEq(address(_priceAggregator), address(priceAggregator));
    }
}

contract Admin is AssetRegistryHelper {
    function setUp() public override {
        AssetRegistryHelper.setUp();
    }

    function 
}
