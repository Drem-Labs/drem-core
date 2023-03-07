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
    constructor(address _dremHub) PriceAggregator(_dremHub) {}

    function validateAggregator(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset) external view {
        _validateAggregator(_aggregator, _rateAsset);
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
        priceAggregator = new PriceAggregator(address(dremHub));
        priceAggregatorHarness = new PriceAggregatorHarness(address(dremHub));
    }
}

contract Admin is PriceAggregatorHelper {
    function setUp() public virtual override {
        PriceAggregatorHelper.setUp();
    }

    function test_AddSupportedAsset() public {
        vm.expectEmit(true, true, true, true);
        emit Events.SupportedAssetAdded(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);
        console.log(block.timestamp);
        (, , , uint256 _updatedAt, ) = AAVE_TO_USD_PRICE_FEED.latestRoundData();
        console.log(_updatedAt);
        priceAggregator.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);

        DataTypes.SupportedAssetInfo memory _aaveInfo = priceAggregator.getSupportedAssetInfo(AAVE_ADDRESS);

        uint256 _aaveUnits = 10 ** (ERC20(AAVE_ADDRESS).decimals());

        assertEq(address(_aaveInfo.aggregator), address(AAVE_TO_USD_PRICE_FEED));
        assertEq(uint256(_aaveInfo.rateAsset), uint256(DataTypes.RateAsset.USD));
        assertEq(_aaveInfo.units, _aaveUnits);
        assertTrue(priceAggregator.isAssetSupported(AAVE_ADDRESS));
    }

    function test_AddSupportedAsset_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));

        vm.expectRevert(Errors.NotHubOwner.selector);
        priceAggregator.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);

        vm.stopPrank();
    }

    function test_AddSupportedAsset_RevertIf_AssetIsZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.addSupportedAsset(address(0), AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);
    }

    function test_AddSupportedAsset_RevertIf_AggregatorIsZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.addSupportedAsset(AAVE_ADDRESS, AggregatorV3Interface(address(0)), DataTypes.RateAsset.USD);
    }

    function test_RemoveSupportedAsset() public {
        priceAggregator.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);
        priceAggregator.removeSupportedAsset(AAVE_ADDRESS);

        DataTypes.SupportedAssetInfo memory _aaveInfo = priceAggregator.getSupportedAssetInfo(AAVE_ADDRESS);

        assertEq(address(_aaveInfo.aggregator), address(0));
        assertEq(uint256(_aaveInfo.rateAsset), 0);
        assertEq(_aaveInfo.units, 0); 
    }

    function test_RemoveSupportedAsset_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));
        
        vm.expectRevert(Errors.NotHubOwner.selector);
        priceAggregator.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);

        vm.stopPrank();
    }

    function test_RemoveSupportedAsset_RevertIf_AssetIsZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.removeSupportedAsset(address(0));
    } 

    function test_SetMaticToUSDAggregator() public {
        vm.expectEmit(true, true, true, true);
        emit Events.MaticToUSDAggregatorSet(MATIC_TO_USD_PRICE_FEED);
        priceAggregator.setMaticToUSDAggregator(MATIC_TO_USD_PRICE_FEED);

    }

    function test_SetMaticToUSDAggregator_RevertIf_NotHubOwner() public {
        vm.startPrank(address(0x67));
        
        vm.expectRevert(Errors.NotHubOwner.selector);
        priceAggregator.setMaticToUSDAggregator(MATIC_TO_USD_PRICE_FEED);

        vm.stopPrank(); 
    }

    function test_SetMaticToUSDAggregator_RevertIf_AggregatorIsZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        priceAggregator.setMaticToUSDAggregator(AggregatorV3Interface(address(0)));
    }

    function test_SetEthToUSDAggregator() public {
        vm.expectEmit(true, true, true, true);
        emit Events.EthToUSDAggregatorSet(ETH_TO_USD_PRICE_FEED);
        priceAggregator.setEthToUSDAggregator(ETH_TO_USD_PRICE_FEED);
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
    function test_Convert_BothUSDRateAsset_AaveToMatic(uint256 _inputAmount) public {
        _inputAmount = bound(_inputAmount, 10**4, 10**40);
        
        priceAggregatorHarness.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);
        priceAggregatorHarness.addSupportedAsset(WMATIC_ADDRESS, MATIC_TO_USD_PRICE_FEED, DataTypes.RateAsset.USD);

        uint256 outputAmount = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);
        assertGt(outputAmount, 0);
        
        (, int256 aaveToUSDRate, , ,) = AAVE_TO_USD_PRICE_FEED.latestRoundData();
        (, int256 maticToUSDRate, , ,) = MATIC_TO_USD_PRICE_FEED.latestRoundData();

        uint256 aaveUnits = 10**ERC20(AAVE_ADDRESS).decimals();
        uint256 maticUnits = 10**ERC20(WMATIC_ADDRESS).decimals();
        
        uint256 impliedOutputAmount = (_inputAmount * uint256(aaveToUSDRate) * (maticUnits)) / (uint256(maticToUSDRate) * aaveUnits);
        assertEq(outputAmount, impliedOutputAmount);
    }
    function test_Convert_BothETHRateAsset_AaveToMatic(uint256 _inputAmount) public {
        _inputAmount = bound(_inputAmount, 10**4, 10**40);
        
        priceAggregatorHarness.addSupportedAsset(AAVE_ADDRESS, AAVE_TO_ETH_PRICE_FEED, DataTypes.RateAsset.ETH);
        priceAggregatorHarness.addSupportedAsset(WMATIC_ADDRESS, MATIC_TO_ETH_PRICE_FEED, DataTypes.RateAsset.ETH);

        uint256 outputAmount = priceAggregatorHarness.convert(_inputAmount, AAVE_ADDRESS, WMATIC_ADDRESS);
        assertGt(outputAmount, 0);
        
        (, int256 aaveToETHRate, , ,) = AAVE_TO_ETH_PRICE_FEED.latestRoundData();
        (, int256 maticToETHRate, , ,) = MATIC_TO_ETH_PRICE_FEED.latestRoundData();

        uint256 aaveUnits = 10**ERC20(AAVE_ADDRESS).decimals();
        uint256 maticUnits = 10**ERC20(WMATIC_ADDRESS).decimals();
        
        uint256 impliedOutputAmount = (_inputAmount * uint256(aaveToETHRate) * (maticUnits)) / (uint256(maticToETHRate) * aaveUnits);
        assertEq(outputAmount, impliedOutputAmount);
    }

    function test_Convert_InputRateUSD_OutputRateETH() public {


        (, int256 _ethToUSDRate, , ,) = ETH_TO_USD_PRICE_FEED.latestRoundData(); 
    }

    function test_Convert_InputETH_OutputUSD() public {}

}