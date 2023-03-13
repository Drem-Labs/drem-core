// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DataTypes} from "../src/finance/libraries/DataTypes.sol";
import {DremHub} from "../src/finance/core/DremHub.sol";
import {Errors} from "../src/finance/libraries/Errors.sol";
import {Events} from "../src/finance/libraries/Events.sol";
import {Fork} from "./reference/Fork.sol";
import {HubOwnable} from "../src/finance/base/HubOwnable.sol";
import {IDremHub} from "../src/finance/interfaces/IDremHub.sol";
import {MockAggregator} from "./reference/MockAggregator.sol";
import {PriceAggregator} from "../src/finance/price-aggregator/PriceAggregator.sol";

contract PriceAggregatorHarness is PriceAggregator {
    constructor(address _dremHub, address _ethToUSDAggregator) PriceAggregator(_dremHub, _ethToUSDAggregator) {}

    function validateAggregator(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset) external view {
        _validateAggregator(_aggregator, _rateAsset);
    }

    function validateAsset(address _asset) external view {
        _validateAsset(_asset);
    }

    function validateRate(int256 _answer, uint256 _updatedAt, DataTypes.RateAsset _rateAsset) external view {
        _validateRate(_answer, _updatedAt, _rateAsset);
    }

    function convert(uint256 _amount, address _inputAsset, address _outputAsset) external view returns (uint256) {
        return _convert(_amount, _inputAsset, _outputAsset);
    }
}
/**
 * Fork inherits Helper
 */

contract PriceAggregatorHelper is Fork {
    DremHub dremHub;
    address dremHubImplementation;
    PriceAggregator priceAggregator;
    PriceAggregatorHarness priceAggregatorHarness;

    function setUp() public virtual override {
        Fork.setUp();
        dremHubImplementation = address(new DremHub());
        dremHub = DremHub(address(new ERC1967Proxy(dremHubImplementation, new bytes(0))));
        dremHub.init();
        priceAggregator = new PriceAggregator(address(dremHub), address(ETH_TO_USD_PRICE_FEED));
        priceAggregatorHarness = new PriceAggregatorHarness(address(dremHub), address(ETH_TO_USD_PRICE_FEED));
    }
}

contract Admin is PriceAggregatorHelper {
    address[] assets;
    AggregatorV3Interface[] aggregators;
    DataTypes.RateAsset[] rateAssets;

    function setUp() public virtual override {
        PriceAggregatorHelper.setUp();

        assets.push(AAVE_ADDRESS);
        assets.push(USDC_ADDRESS);
        assets.push(WMATIC_ADDRESS);

        aggregators.push(AAVE_TO_USD_PRICE_FEED);
        aggregators.push(USDC_TO_USD_PRICE_FEED);
        aggregators.push(MATIC_TO_USD_PRICE_FEED);

        for (uint256 i; i < 3; i++) {
            rateAssets.push(DataTypes.RateAsset.USD);
        }
    }

    function test_AddSupportedAssets() public {
        address[] memory _assets = new address[](1);
        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](1);
        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](1);

        _assets[0] = AAVE_ADDRESS;
        _aggregators[0] = AAVE_TO_USD_PRICE_FEED;
        _rateAssets[0] = DataTypes.RateAsset.USD;

        vm.expectEmit(true, true, true, true);
        emit Events.SupportedAssetAdded(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);
        priceAggregator.addSupportedAssets(_assets, _aggregators, _rateAssets);

        DataTypes.SupportedAssetInfo memory _aaveInfo = priceAggregator.getSupportedAssetInfo(AAVE_ADDRESS);

        uint256 _aaveUnits = 10 ** (ERC20(AAVE_ADDRESS).decimals());

        assertEq(address(_aaveInfo.aggregator), address(AAVE_TO_USD_PRICE_FEED));
        assertEq(uint256(_aaveInfo.rateAsset), uint256(DataTypes.RateAsset.USD));
        assertEq(_aaveInfo.units, _aaveUnits);
        assertTrue(priceAggregator.isAssetSupported(AAVE_ADDRESS));
    }

    function test_AddSupportedAssets_RevertIf_EmptyArray() public {
        address[] memory _emptyAddressArray;
        AggregatorV3Interface[] memory _emptyAggregatorArray;
        DataTypes.RateAsset[] memory _emptyRateAssetArray;

        vm.expectRevert(Errors.EmptyArray.selector);
        priceAggregator.addSupportedAssets(_emptyAddressArray, aggregators, rateAssets);

        vm.expectRevert(Errors.InvalidAssetArrays.selector);
        priceAggregator.addSupportedAssets(assets, _emptyAggregatorArray, rateAssets);

        vm.expectRevert(Errors.InvalidAssetArrays.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, _emptyRateAssetArray);
    }

    function test_AddSupportedAssets_RevertIf_NotEqualArrayLengths() public {
        // Assets length == 2; aggregators length == 3; rate assets length == 3
        assets.pop();

        vm.expectRevert(Errors.InvalidAssetArrays.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);

        // Assets length == 2; aggregators length == 3; rate assets length == 2
        rateAssets.pop();

        vm.expectRevert(Errors.InvalidAssetArrays.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);

        // Assets length == 1; aggregators length == 1; rate assets length == 2
        aggregators.pop();
        aggregators.pop();
        assets.pop();

        vm.expectRevert(Errors.InvalidAssetArrays.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);
    }

    function test_AddSupportedAsset_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));

        vm.expectRevert(Errors.NotHubOwner.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);

        vm.stopPrank();
    }

    function test_AddSupportedAsset_RevertIf_AssetIsZeroAddress() public {
        assets[0] = address(0);

        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);
    }

    function test_AddSupportedAsset_RevertIf_AggregatorIsZeroAddress() public {
        aggregators[0] = AggregatorV3Interface(address(0));

        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);
    }

    function test_RemoveSupportedAsset() public {
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);
        priceAggregator.removeSupportedAssets(assets);

        DataTypes.SupportedAssetInfo memory _aaveInfo = priceAggregator.getSupportedAssetInfo(AAVE_ADDRESS);

        assertEq(address(_aaveInfo.aggregator), address(0));
        assertEq(uint256(_aaveInfo.rateAsset), 0);
        assertEq(_aaveInfo.units, 0);
    }

    function test_RemoveSupportedAssets_RevertIf_EmptyAssetArray() public {
        address[] memory _emptyAssetArray = new address[](0);

        vm.expectRevert(Errors.EmptyArray.selector);
        priceAggregator.removeSupportedAssets(_emptyAssetArray);
    }

    function test_RemoveSupportedAsset_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));

        vm.expectRevert(Errors.NotHubOwner.selector);
        priceAggregator.addSupportedAssets(assets, aggregators, rateAssets);

        vm.stopPrank();
    }

    function test_RemoveSupportedAsset_RevertIf_AssetIsZeroAddress() public {
        assets[0] = address(0);

        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.removeSupportedAssets(assets);
    }

    function test_SetEthToUSDAggregator() public {
        vm.expectEmit(true, true, true, true);
        emit Events.EthToUSDAggregatorSet(ETH_TO_USD_PRICE_FEED);
        priceAggregator.setEthToUSDAggregator(ETH_TO_USD_PRICE_FEED);

        assertEq(address(priceAggregator.getEthToUSDAggregator()), address(ETH_TO_USD_PRICE_FEED));
    }

    function test_SetEthToUSDAggregator_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));

        vm.expectRevert(Errors.NotHubOwner.selector);
        priceAggregator.setEthToUSDAggregator(ETH_TO_USD_PRICE_FEED);

        vm.stopPrank();
    }

    function test_SetEthToUSDAggregator_RevertIf_AggregatorIsZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.setEthToUSDAggregator(AggregatorV3Interface(address(0)));
    }

    function test_SetEthToUSDAggregator_RevertIf_InvalidRate() public {
        MockAggregator _mockAggregator = new MockAggregator();
        vm.expectRevert(Errors.InvalidAggregatorRate.selector);
        priceAggregator.setEthToUSDAggregator(_mockAggregator);
    }

    function test_SetEthToUSDAggregator_RevertIf_StalePrice() public {
        MockAggregator _mockAggregator = new MockAggregator();
        skip(priceAggregator.STALE_USD_PRICE_LIMIT() + 1);
        _mockAggregator.setAnswer(1);

        vm.expectRevert(Errors.StaleUSDRate.selector);
        priceAggregator.setEthToUSDAggregator(_mockAggregator);
    }
}

contract Internal is PriceAggregatorHelper {
    function setUp() public virtual override {
        PriceAggregatorHelper.setUp();
    }

    function test_ValidateUSDRate() public view {
        uint256 _validUpdate = block.timestamp - priceAggregatorHarness.STALE_USD_PRICE_LIMIT();

        DataTypes.RateAsset _rateAsset = DataTypes.RateAsset.USD;

        priceAggregatorHarness.validateRate(1, _validUpdate, _rateAsset);
    }

    function test_ValidateUSDRate_RevertIf_Stale() public {
        uint256 _invalidUpdate = block.timestamp - priceAggregatorHarness.STALE_USD_PRICE_LIMIT() - 1;
        DataTypes.RateAsset _rateAsset = DataTypes.RateAsset.USD;

        vm.expectRevert(Errors.StaleUSDRate.selector);
        priceAggregatorHarness.validateRate(1, _invalidUpdate, _rateAsset);
    }

    function test_ValidateETHRate() public view {
        uint256 _validUpdate = block.timestamp - priceAggregatorHarness.STALE_ETH_PRICE_LIMIT();

        DataTypes.RateAsset _rateAsset = DataTypes.RateAsset.ETH;

        priceAggregatorHarness.validateRate(1, _validUpdate, _rateAsset);
    }

    function test_ValidateETHRate_RevertIf_Stale() public {
        uint256 _invalidUpdate = block.timestamp - priceAggregatorHarness.STALE_ETH_PRICE_LIMIT() - 1;
        DataTypes.RateAsset _rateAsset = DataTypes.RateAsset.ETH;

        vm.expectRevert(Errors.StaleEthRate.selector);
        priceAggregatorHarness.validateRate(1, _invalidUpdate, _rateAsset);
    }

    function test_ValidateRate_RevertIf_Zero() public {
        uint256 _validUpdate = block.timestamp - priceAggregatorHarness.STALE_ETH_PRICE_LIMIT();

        DataTypes.RateAsset _rateAsset = DataTypes.RateAsset.ETH;

        vm.expectRevert(Errors.InvalidAggregatorRate.selector);
        priceAggregatorHarness.validateRate(0, _validUpdate, _rateAsset);
    }

    function test_ValidateAggregator() public view {
        priceAggregatorHarness.validateAggregator(AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);
    }

    function test_ValidateAsset() public {
        vm.expectRevert(Errors.AssetNotSupported.selector);
        priceAggregatorHarness.validateAsset(USDC_ADDRESS);
    }
}

contract External is PriceAggregatorHelper {
    function setUp() public virtual override {
        PriceAggregatorHelper.setUp();
    }

    function test_ConvertAssets() public {
        address[] memory _inputAssets = new address[](4);
        uint256[] memory _inputAmounts = new uint256[](4);

        // _inputAssets are AAVE, USDT, USDC, and ETH
        _inputAssets[0] = AAVE_ADDRESS;
        _inputAssets[1] = USDT_ADDRESS;
        _inputAssets[2] = USDC_ADDRESS;
        _inputAssets[3] = WETH_ADDRESS;

        // _inputs are 100 AAVE, 100 USDT, 100 USDC, and 1 ETH
        _inputAmounts[0] = 100e18;
        _inputAmounts[1] = 100e6;
        _inputAmounts[2] = 100e6;
        _inputAmounts[3] = 1e18;

        address[] memory _assets = new address[](5);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = USDC_ADDRESS;
        _assets[2] = USDT_ADDRESS;
        _assets[3] = WETH_ADDRESS;
        _assets[4] = WMATIC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](5);
        _aggregators[0] = AAVE_TO_ETH_PRICE_FEED;
        _aggregators[1] = USDC_TO_USD_PRICE_FEED;
        _aggregators[2] = USDT_TO_USD_PRICE_FEED;
        _aggregators[3] = ETH_TO_USD_PRICE_FEED;
        _aggregators[4] = MATIC_TO_USD_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](5);
        _rateAssets[0] = DataTypes.RateAsset.ETH;
        for (uint256 i = 1; i < 5; ++i) {
            _rateAssets[i] = DataTypes.RateAsset.USD;
        }

        priceAggregator.addSupportedAssets(_assets, _aggregators, _rateAssets);

        // Implied value is 8467.22429907
        // Price returned by the aggregator is roughly equal to 8446
        // Off by -0.2%...
        priceAggregator.convertAssets(_inputAmounts, _inputAssets, WMATIC_ADDRESS);
    }

    function test_ConvertAssets_RevertIf_InvalidOutputAsset() public {
        address[] memory _inputAssets = new address[](1);
        uint256[] memory _inputAmounts = new uint256[](1);

        _inputAssets[0] = AAVE_ADDRESS;
        _inputAmounts[0] = 100e18;

        address[] memory _assets = new address[](1);
        _assets[0] = AAVE_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](1);
        _aggregators[0] = AAVE_TO_ETH_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](1);
        _rateAssets[0] = DataTypes.RateAsset.ETH;

        priceAggregator.addSupportedAssets(_assets, _aggregators, _rateAssets);

        vm.expectRevert(Errors.AssetNotSupported.selector);
        priceAggregator.convertAssets(_inputAmounts, _inputAssets, WMATIC_ADDRESS);
    }

    function test_ConvertAssets_RevertIf_InputValueTooSmall() public {
        uint256[] memory _inputAmounts = new uint256[](1);
        address[] memory _inputAssets = new address[](1);

        _inputAmounts[0] = 1e3;
        _inputAssets[0] = AAVE_ADDRESS;

        address[] memory _assets = new address[](2);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = USDC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](2);
        _aggregators[0] = AAVE_TO_ETH_PRICE_FEED;
        _aggregators[1] = USDC_TO_USD_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](2);
        _rateAssets[0] = DataTypes.RateAsset.ETH;
        _rateAssets[1] = DataTypes.RateAsset.USD;

        priceAggregator.addSupportedAssets(_assets, _aggregators, _rateAssets);

        vm.expectRevert(Errors.InvalidConversion.selector);
        priceAggregator.convertAssets(_inputAmounts, _inputAssets, USDC_ADDRESS);
    }

    function test_InvalidInputAssetAndInputAmountLengths() public {
        uint256[] memory _inputAmounts = new uint256[](1);
        address[] memory _inputAssets = new address[](2);

        vm.expectRevert(Errors.InvalidInputArrays.selector);
        priceAggregator.convertAssets(_inputAmounts, _inputAssets, USDC_ADDRESS);
    }
}

contract Fuzz is PriceAggregatorHelper {
    function setUp() public virtual override {
        PriceAggregatorHelper.setUp();
    }
    /**
     * @dev Input Asset: AAVE
     * Output Asset: WMATIC
     * Both have 18 decimals...
     */

    function testFuzz_Convert_BothUSDRateAsset(uint256 _inputAmount) public {
        _inputAmount = bound(_inputAmount, 1e4, 1e40);

        address[] memory _assets = new address[](2);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = WMATIC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](2);
        _aggregators[0] = AAVE_TO_USD_PRICE_FEED;
        _aggregators[1] = MATIC_TO_USD_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](2);
        _rateAssets[0] = DataTypes.RateAsset.USD;
        _rateAssets[1] = DataTypes.RateAsset.USD;

        priceAggregatorHarness.addSupportedAssets(_assets, _aggregators, _rateAssets);

        uint256 outputAmount = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);
        assertGt(outputAmount, 0);

        (, int256 aaveToUSDRate,,,) = AAVE_TO_USD_PRICE_FEED.latestRoundData();
        (, int256 maticToUSDRate,,,) = MATIC_TO_USD_PRICE_FEED.latestRoundData();

        uint256 aaveUnits = 10 ** ERC20(AAVE_ADDRESS).decimals();
        uint256 maticUnits = 10 ** ERC20(WMATIC_ADDRESS).decimals();

        uint256 impliedOutputAmount =
            (_inputAmount * uint256(aaveToUSDRate) * (maticUnits)) / (uint256(maticToUSDRate) * aaveUnits);
        assertEq(outputAmount, impliedOutputAmount);
    }

    function testFuzz_Convert_BothETHRateAsset(uint256 _inputAmount) public {
        _inputAmount = bound(_inputAmount, 1e4, 1e40);

        address[] memory _assets = new address[](2);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = WMATIC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](2);
        _aggregators[0] = AAVE_TO_ETH_PRICE_FEED;
        _aggregators[1] = MATIC_TO_ETH_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](2);
        _rateAssets[0] = DataTypes.RateAsset.ETH;
        _rateAssets[1] = DataTypes.RateAsset.ETH;

        priceAggregatorHarness.addSupportedAssets(_assets, _aggregators, _rateAssets);

        uint256 outputAmount = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);
        assertGt(outputAmount, 0);

        (, int256 aaveToETHRate,,,) = AAVE_TO_ETH_PRICE_FEED.latestRoundData();
        (, int256 maticToETHRate,,,) = MATIC_TO_ETH_PRICE_FEED.latestRoundData();

        uint256 aaveUnits = 10 ** ERC20(AAVE_ADDRESS).decimals();
        uint256 maticUnits = 10 ** ERC20(WMATIC_ADDRESS).decimals();

        uint256 impliedOutputAmount =
            (_inputAmount * uint256(aaveToETHRate) * (maticUnits)) / (uint256(maticToETHRate) * aaveUnits);
        assertEq(outputAmount, impliedOutputAmount);
    }

    function testFuzz_Convert_InputRateUSD_OutputRateETH(uint256 _inputAmount) public {
        _inputAmount = bound(_inputAmount, 1e4, 1e40);

        address[] memory _assets = new address[](2);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = WMATIC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](2);
        _aggregators[0] = AAVE_TO_USD_PRICE_FEED;
        _aggregators[1] = MATIC_TO_ETH_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](2);
        _rateAssets[0] = DataTypes.RateAsset.USD;
        _rateAssets[1] = DataTypes.RateAsset.ETH;

        priceAggregatorHarness.addSupportedAssets(_assets, _aggregators, _rateAssets);

        uint256 outputAmount = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);
        assertGt(outputAmount, 0);

        (, int256 aaveToUSDRate,,,) = AAVE_TO_USD_PRICE_FEED.latestRoundData();
        (, int256 maticToETHRate,,,) = MATIC_TO_ETH_PRICE_FEED.latestRoundData();
        (, int256 ethToUSDRate,,,) = ETH_TO_USD_PRICE_FEED.latestRoundData();

        uint256 aaveUnits = 10 ** (ERC20(AAVE_ADDRESS).decimals());
        uint256 maticUnits = 10 ** (ERC20(WMATIC_ADDRESS).decimals());

        uint256 overflowAdjustment = (_inputAmount * uint256(aaveToUSDRate) * maticUnits) / aaveUnits;
        uint256 impliedOutputAmount =
            (overflowAdjustment * CHAINLINK_ETH_UNITS) / (uint256(maticToETHRate) * uint256(ethToUSDRate));
        assertEq(outputAmount, impliedOutputAmount);
    }

    function testFuzz_Convert_InputETH_OutputUSD(uint256 _inputAmount) public {
        _inputAmount = bound(_inputAmount, 1e4, 1e40);

        address[] memory _assets = new address[](2);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = WMATIC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](2);
        _aggregators[0] = AAVE_TO_ETH_PRICE_FEED;
        _aggregators[1] = MATIC_TO_USD_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](2);
        _rateAssets[0] = DataTypes.RateAsset.ETH;
        _rateAssets[1] = DataTypes.RateAsset.USD;

        priceAggregatorHarness.addSupportedAssets(_assets, _aggregators, _rateAssets);

        uint256 outputAmount = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);
        assertGt(outputAmount, 0);
        console.log(outputAmount);

        (, int256 aaveToETHRate,,,) = AAVE_TO_ETH_PRICE_FEED.latestRoundData();
        (, int256 maticToUSDRate,,,) = MATIC_TO_USD_PRICE_FEED.latestRoundData();
        (, int256 ethToUSDRate,,,) = ETH_TO_USD_PRICE_FEED.latestRoundData();

        uint256 aaveUnits = 10 ** (ERC20(AAVE_ADDRESS).decimals());
        uint256 maticUnits = 10 ** (ERC20(WMATIC_ADDRESS).decimals());

        uint256 overflowAdjustment = (_inputAmount * uint256(aaveToETHRate) * maticUnits) / aaveUnits;
        uint256 impliedOutputAmount =
            (overflowAdjustment * uint256(ethToUSDRate)) / (uint256(maticToUSDRate) * CHAINLINK_ETH_UNITS);

        assertEq(outputAmount, impliedOutputAmount);
    }

    function testFuzz_AllInputAndOutputCombos(uint256 _inputAmount) public {
        _inputAmount = bound(_inputAmount, 1e4, 1e40);

        address[] memory _assets = new address[](2);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = WMATIC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](2);
        _aggregators[0] = AAVE_TO_USD_PRICE_FEED;
        _aggregators[1] = MATIC_TO_USD_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](2);
        _rateAssets[0] = DataTypes.RateAsset.ETH;
        _rateAssets[1] = DataTypes.RateAsset.USD;

        priceAggregatorHarness.addSupportedAssets(_assets, _aggregators, _rateAssets);

        uint256 bothUSDRateConversion = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);

        _aggregators[1] = MATIC_TO_ETH_PRICE_FEED;
        _rateAssets[1] = DataTypes.RateAsset.ETH;

        uint256 usdRateToEthRateConversion = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);

        _aggregators[0] = AAVE_TO_ETH_PRICE_FEED;
        _rateAssets[0] = DataTypes.RateAsset.ETH;

        uint256 bothETHRateConversion = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);

        _aggregators[1] = MATIC_TO_USD_PRICE_FEED;
        _rateAssets[1] = DataTypes.RateAsset.USD;

        uint256 ethRateToUsdRateConversion = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);

        // Assert that the conversions are within 1% of each other
        assertApproxEqRel(bothUSDRateConversion, bothETHRateConversion, 1e16, "Both ETH Rate off");
        assertApproxEqRel(bothUSDRateConversion, usdRateToEthRateConversion, 1e16, "USD to ETH Rate off");
        assertApproxEqRel(bothUSDRateConversion, ethRateToUsdRateConversion, 1e16, "ETH to USD Rate off");
    }

    function testFuzz_ConvertAssets(
        uint256 _inputAmount0,
        uint256 _inputAmount1,
        uint256 _inputAmount2,
        uint256 _inputAmount3
    ) public {
        address[] memory _inputAssets = new address[](4);
        uint256[] memory _inputAmounts = new uint256[](4);

        // _inputAssets are AAVE, USDT, USDC, and ETH
        _inputAssets[0] = AAVE_ADDRESS;
        _inputAssets[1] = USDT_ADDRESS;
        _inputAssets[2] = USDC_ADDRESS;
        _inputAssets[3] = WETH_ADDRESS;

        // AAVE is bounded from 1e-14 to 1e22 AAVE
        _inputAmount0 = bound(_inputAmount0, 1e4, 1e40);

        // USDT is bounded from 1e-3 USDT to 1e22 USDT
        _inputAmount1 = bound(_inputAmount1, 1e3, 1e28);

        // USDC is bounded from 1e-3 USDC to 1e22 USDC
        _inputAmount2 = bound(_inputAmount1, 1e3, 1e28);

        // WETH is bounded from 1e-14 to 1e22 ETH
        _inputAmount3 = bound(_inputAmount0, 1e4, 1e40);

        // _inputs are 100 AAVE, 100 USDT, 100 USDC, and 1 ETH
        _inputAmounts[0] = _inputAmount0;
        _inputAmounts[1] = _inputAmount1;
        _inputAmounts[2] = _inputAmount2;
        _inputAmounts[3] = _inputAmount3;

        address[] memory _assets = new address[](5);
        _assets[0] = AAVE_ADDRESS;
        _assets[1] = USDC_ADDRESS;
        _assets[2] = USDT_ADDRESS;
        _assets[3] = WETH_ADDRESS;
        _assets[4] = WMATIC_ADDRESS;

        AggregatorV3Interface[] memory _aggregators = new AggregatorV3Interface[](5);
        _aggregators[0] = AAVE_TO_ETH_PRICE_FEED;
        _aggregators[1] = USDC_TO_USD_PRICE_FEED;
        _aggregators[2] = USDT_TO_USD_PRICE_FEED;
        _aggregators[3] = ETH_TO_USD_PRICE_FEED;
        _aggregators[4] = MATIC_TO_USD_PRICE_FEED;

        DataTypes.RateAsset[] memory _rateAssets = new DataTypes.RateAsset[](5);
        _rateAssets[0] = DataTypes.RateAsset.ETH;
        for (uint256 i = 1; i < 5; ++i) {
            _rateAssets[i] = DataTypes.RateAsset.USD;
        }

        priceAggregator.addSupportedAssets(_assets, _aggregators, _rateAssets);

        priceAggregator.convertAssets(_inputAmounts, _inputAssets, WMATIC_ADDRESS);
    }
}
