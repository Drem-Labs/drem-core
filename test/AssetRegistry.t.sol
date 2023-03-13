// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetRegistry} from "../src/finance/asset-registry/AssetRegistry.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {DataTypes} from "../src/finance/libraries/DataTypes.sol";
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

    address[] assets;
    AggregatorV3Interface [] aggregators;

    function setUp() public virtual override {
        Fork.setUp();

        dremHubImplementation = address(new DremHub());
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));
        dremHub.init();

        priceAggregator = new PriceAggregator(address(dremHub), address(ETH_TO_USD_PRICE_FEED));

        assetRegistryImplementation = address(new AssetRegistry(address(dremHub), address(priceAggregator)));
        assetRegistry = AssetRegistry(address(new ERC1967Proxy(assetRegistryImplementation, new bytes(0))));

        assets.push(AAVE_ADDRESS);
        assets.push(USDC_ADDRESS);
        assets.push(WMATIC_ADDRESS);

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](3);
        _aggregators[0] =  AAVE_TO_USD_PRICE_FEED;
        _aggregators[1] =  USDC_TO_USD_PRICE_FEED;
        _aggregators[2] =  MATIC_TO_USD_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](3);

        for (uint256 i; i < 3; i++) {
            _rateAssets[i] = DataTypes.RateAsset.USD;
        }

        priceAggregator.addSupportedAssets(assets, _aggregators, _rateAssets);
    }

    function test_setUp() public {
        address _priceAggregator = address(assetRegistry.getPriceAggregator());
        assertEq(_priceAggregator, address(priceAggregator));

        DataTypes.SupportedAssetInfo memory _aaveInfo = priceAggregator.getSupportedAssetInfo(AAVE_ADDRESS);
        DataTypes.SupportedAssetInfo memory _usdcInfo = priceAggregator.getSupportedAssetInfo(USDC_ADDRESS);
        DataTypes.SupportedAssetInfo memory _maticInfo = priceAggregator.getSupportedAssetInfo(WMATIC_ADDRESS); 

        assertEq(address(_aaveInfo.aggregator), address(AAVE_TO_USD_PRICE_FEED));
        assertEq(uint256(_aaveInfo.rateAsset), uint256(DataTypes.RateAsset.USD));
        assertEq(_aaveInfo.units, 1e18);

        assertEq(address(_usdcInfo.aggregator), address(USDC_TO_USD_PRICE_FEED));
        assertEq(uint256(_usdcInfo.rateAsset), uint256(DataTypes.RateAsset.USD));
        assertEq(_usdcInfo.units, 1e6);

        assertEq(address(_maticInfo.aggregator), address(MATIC_TO_USD_PRICE_FEED));
        assertEq(uint256(_maticInfo.rateAsset), uint256(DataTypes.RateAsset.USD));
        assertEq(_maticInfo.units, 1e18);
    }
}

contract Admin is AssetRegistryHelper {
    function setUp() public override {
        AssetRegistryHelper.setUp();
    }

    function test_WhitelistAssets() public {    

        vm.expectEmit(true, true, true, true);
        emit Events.WhitelistedAssetsAdded(assets);

        assetRegistry.whitelistAssets(assets);

        assertTrue(assetRegistry.isAssetWhitelisted(AAVE_ADDRESS));
        assertTrue(assetRegistry.isAssetWhitelisted(USDC_ADDRESS));
        assertTrue(assetRegistry.isAssetWhitelisted(WMATIC_ADDRESS));

        address[] memory _assets = assetRegistry.getWhitelistedAssets();

        bool _containsInvalidAsset = false;

        // Ordering is not guaranteed in enumerable set
        for(uint256 i; i < _assets.length; i++) {
            if (_assets[i] == AAVE_ADDRESS || _assets[i] == USDC_ADDRESS || _assets[i] == WMATIC_ADDRESS) {
                continue;
            }

            _containsInvalidAsset = true;
        }

        assertFalse(_containsInvalidAsset);
    }

    function test_WhitelistAssets_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));

        vm.expectRevert(Errors.NotHubOwner.selector);
        assetRegistry.whitelistAssets(assets); 

        vm.stopPrank();
    }

    function test_WhitelistAssets_RevertIf_EmptyArray() public {
        address[] memory _emptyAddressArray = new address[](0);

        vm.expectRevert(Errors.EmptyArray.selector); 
        assetRegistry.whitelistAssets(_emptyAddressArray);
    }

    function test_WhitelistAssets_RevertIf_ZeroAddress() public {
        assets[1] = address(0);

        vm.expectRevert(Errors.ZeroAddress.selector); 
        assetRegistry.whitelistAssets(assets); 
    }

    function test_WhitelistAssets_RevertIf_AssetNotSupported() public {
        address[] memory _toRemove = new address[](1);
        _toRemove[0] = USDC_ADDRESS;

        priceAggregator.removeSupportedAssets(_toRemove);

        vm.expectRevert(Errors.AssetNotSupported.selector);
        assetRegistry.whitelistAssets(assets);
    }

    function test_WhitelistAssets_RevertIf_AssetAlreadyWhitelisted() public {
        address[] memory _redundantAsset = new address[](1);
        _redundantAsset[0] = USDC_ADDRESS;

        assetRegistry.whitelistAssets(assets); 

        vm.expectRevert(Errors.AssetAlreadyWhitelisted.selector);
        assetRegistry.whitelistAssets(_redundantAsset);
    }

    function test_removeWhitelistedAssets() public {

        // Arrange
        assetRegistry.whitelistAssets(assets);
        address[] memory _values = assetRegistry.getWhitelistedAssets();
        assertEq(_values.length, 3);

        vm.expectEmit(true, true, true, true);
        emit Events.WhitelistedAssetsRemoved(assets);

        assetRegistry.removeWhitelistedAssets(assets);

        _values = assetRegistry.getWhitelistedAssets();
        assertEq(_values.length, 0); 
    }

    function test_RemoveWhitelistedAssets_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));

        vm.expectRevert(Errors.NotHubOwner.selector);
        assetRegistry.removeWhitelistedAssets(assets); 

        vm.stopPrank();
    }

    function test_RemoveWhitelistedAssets_RevertIf_EmptyArray() public {
        address[] memory _emptyArray;

        vm.expectRevert(Errors.EmptyArray.selector);
        assetRegistry.removeWhitelistedAssets(_emptyArray);
    }

    function test_RemoveWhitelistedAssets_RevertIf_AssetNotWhitelisted() public {
        address[] memory _nonWhitelistedAsset = new address[](1);
        _nonWhitelistedAsset[0] =  DAI_ADDRESS;

        vm.expectRevert(Errors.AssetNotWhitelisted.selector);
        assetRegistry.removeWhitelistedAssets(_nonWhitelistedAsset);
    }

    function test_RemoveWhitelistedAssets_RevertIf_AssetZeroAddress() public {
        address[] memory _zeroAddress = new address[](1);
        _zeroAddress[0] =  address(0);

        vm.expectRevert(Errors.ZeroAddress.selector);
        assetRegistry.removeWhitelistedAssets(_zeroAddress);
    }


    function test_UUPSUpgrade() public {}
}
