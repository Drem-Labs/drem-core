// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetRegistry} from "../src/finance/asset-registry/AssetRegistry.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {Errors} from "../src/finance/libraries/Errors.sol";
import {Events} from "../src/finance/libraries/Events.sol";
import {Fork} from "./reference/Fork.sol";
import {PriceAggregator} from "../src/finance/price-aggregator/PriceAggregator.sol";

contract AssetRegistryHelper is Fork {
    DremHub dremHub;
    address dremHubImplementation;

    PriceAggregator priceAggregator;

    AssetRegistry assetRegistry;
    address assetRegistryImplementation;

    function setUp() public virtual override {
        Fork.setUp();

        dremHubImplementation = address(new DremHub());
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));

        priceAggregator = new PriceAggregator(address(dremHub), address(ETH_TO_USD_PRICE_FEED));

        assetRegistryImplementation = address(new AssetRegistry(address(dremHub), priceAggregator));
        assetRegistry = AssetRegistry(address(new ERC1967Proxy(assetRegistryImplementation, new bytes(0))));
    }

    function test_setUp() public {
        address _priceAggregator = address(assetRegistry.getPriceAggregator());
        assertEq(_priceAggregator, address(priceAggregator));
    }
}

contract Admin is AssetRegistryHelper {
    function setUp() public override {
        AssetRegistryHelper.setUp();
    }

    

    function test_WhitelistAssets() public {

        address[] memory _assets = new address[](3);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = USDC_ADDRESS;
        _assets[2] = WETH_ADDRESS;

    }

    function test_WhitelistAssets_RevertIf_NotHubOwner() public {}

    function test_WhitelistAssets_RevertIf_EmptyArray() public {}

    function test_WhitelistAssets_RevertIf_ZeroAddress() public {}

    function test_WhitelistAssets_RevertIf_AssetNotSupported() public {}

    function test_WhitelistAssets_RevertIf_AssetAlreadyWhitelisted() public {}

    function test_removeWhitelistedAssets() public {}

    function test_RemoveWhitelistedAssets_RevertIf_NotHubOwner() public {}

    function test_RemoveWhitelistedAssets_RevertIf_EmptyArray() public {}

    function test_RemoveWhitelistedAssets_RevertIf_AssetNotWhitelisted() public {}

    function test_UUPSUpgrade() public {}
}
