// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferLib} from "./TransferLib.sol";
import {BaseStep} from "../../BaseStep.sol";
import {IGAValuer} from "../../../interfaces/IGAValuer.sol";
import {IVault} from "../../../interfaces/IVault.sol";
import {IFeeController} from "../../../interfaces/IFeeController.sol";

contract TransferStep is BaseStep {
    // add whatever assets are allowed as denomination assets
    mapping(address => bool) public denominationAssets;

    // keep all the stepData
    mapping(address => mapping(uint256 => TransferLib.FixedArgData)) public stepData;

    // valuer
    address public GAValuer;

    // entrance/exit fees
    TransferLib.FeeData public fees;

    // set the address to receive the fees (we can have multiple, but they should all adhere to some general interface)
    address feeCollector;

    // controls how many fees are paid
    address feeController;

    // constructor --> set the GAValuer
    constructor(address _dremHub, address _GAValuer, TransferLib.FeeData memory _fees, address _feeCollector) BaseStep(_dremHub) {
        _setGAValuer(_GAValuer);
        _setFees(_fees);
        _setFeeCollector(_feeCollector);
    }

    // initialized with the denomination asset and the tracked assets
    function init(uint256 _argIndex, bytes calldata _fixedArgs) external {
        // turn the fixed args into a useful struct
        TransferLib.FixedArgData memory argData = abi.decode(_fixedArgs, (TransferLib.FixedArgData));

        // validate the denomination asset
        if (!denominationAssets[argData.denominationAsset]) revert TransferLib.InvalidDenominationAsset();

        // store the stepData (can store to msg.sender to ensure that only the vaults can interact with this)
        stepData[msg.sender][_argIndex] = argData;
    }

    // wind function --> transfer some assets
    function wind(uint256 _argIndex, bytes memory _variableArgs) external {
        // get the funds from the args (this is a required input to transfer --> more exact to calculate shares out)
        TransferLib.VariableArgData memory argData = abi.decode(_variableArgs, (TransferLib.VariableArgData));

        // get the fixed data
        TransferLib.FixedArgData memory fixedData = stepData[msg.sender][_argIndex];

        // split the funds and fees
        TransferLib.Distribution memory fundSplit = _splitFunds(argData.funds);


        // get the value of the vault --> going to be in some safe denomination asset --> can use this as a true value to calculate shares
        uint256 vaultValue = IGAValuer(GAValuer).getVaultValue(msg.sender, fixedData.denominationAsset);

        // get the number of shares of the vault
        uint256 vaultSharesOutstanding = IERC20(msg.sender).totalSupply();

        // if there are shares, ensure that the number of shares will be less than or equal to the expected value (if will get more shares, rewrite the sharesExpected)
        // if there are no shares, leave the shares alone
        if (vaultSharesOutstanding > 0) {
            // revert if shares price is less than reality
            if ((fundSplit.purchase / argData.shares) < (vaultValue / vaultSharesOutstanding)) revert TransferLib.InsufficientFunds();

            // if not reverted, set the number of shares to the max that the funds will buy
            // keeping the ratio here and multiplying first maximizes accuracy and minimizes rounding in the case of small vault values
            argData.shares = fundSplit.purchase * vaultValue / vaultSharesOutstanding;
        }

        // mint some shares (accounting before transfer)
        IVault(msg.sender).mintShares(argData.shares, argData.caller);

        // transfer funds in (will revert if the user attempts to purchase shares they cannot afford)
        IERC20(fixedData.denominationAsset).transferFrom(argData.caller, msg.sender, fundSplit.purchase);

        // transfer fees
        IERC20(fixedData.denominationAsset).transferFrom(argData.caller, msg.sender, fundSplit.fee);

        // emit the event that some shares were minted at some price
        emit TransferLib.SharesRedeemed(argData.shares, fundSplit.purchase);
    }

    // unwind function --> transfer the assets back
    function unwind(uint256 _argIndex, bytes memory _variableArgs) external {
        // get the funds from the args (this is a required input to transfer --> more exact to calculate shares out)
        TransferLib.VariableArgData memory argData = abi.decode(_variableArgs, (TransferLib.VariableArgData));

        // get the fixed data
        TransferLib.FixedArgData memory fixedData = stepData[msg.sender][_argIndex];

        // figure out who the caller is

        // ensure that they are allowed to liquidate these many shares

        // calculate the number of funds per share --> get the value of the vault

        // burn some shares

        // push the funds from the vault to the user (should be done in generalist function)

        // transfer fees (should be done in generalist function)

    }

    // set allowed denomination assets (must be very liquid, not just tracked)
    function setDenominationAssst(address _assetAddress, bool _assetAllowed) external onlyHubOwner {
        denominationAssets[_assetAddress] = _assetAllowed;
    }

    // set the valuer (only the hub owner)
    function setGAValuer(address _GAValuer) external onlyHubOwner {
        _setGAValuer(_GAValuer);
    }

    // set the fees (external)
    function setFees(TransferLib.FeeData memory _fees) external onlyHubOwner {
        _setFees(_fees);
    }

    // set the fee collector
    function setFeeCollector(address _feeCollector) external onlyHubOwner {
        _setFeeCollector(_feeCollector);
    }

    // set the fee controller
    function setFeeController(address _feeController) external onlyHubOwner {
        _setFeeController(_feeController);
    }

    // get the funds split
    function _splitFunds(uint256 _funds) internal returns(TransferLib.Distribution memory) {
        // allocate some memory to the distribution
        TransferLib.Distribution memory fundSplit;

        // get the fee that the user will incur (will be handled by the fee controller)
        fundSplit.fee = IFeeController(feeController).calculateFee(_funds, msg.sender);

        // get the remaining purchasing power
        fundSplit.purchase = _funds - fundSplit.fee;

        // return this information back to the caller
        return(fundSplit);
    }

    // set the valuer (internal)
    function _setGAValuer(address _GAValuer) internal {
        GAValuer = _GAValuer;
    }

    // set the step fees (internal)
    function _setFees(TransferLib.FeeData memory _fees) internal {
        fees = _fees;
    }

    // set the fee collector (internal)
    function _setFeeCollector(address _feeCollector) internal {
        feeCollector = _feeCollector;
    }

    // set the fee controller (internal)
    function _setFeeController(address _feeController) internal {
        feeController = _feeController;
    }
}
