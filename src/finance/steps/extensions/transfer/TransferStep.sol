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
            if ((fundSplit.funds / argData.shares) < (vaultValue / vaultSharesOutstanding)) revert TransferLib.InsufficientFunds();

            // if not reverted, set the number of shares to the max that the funds will buy
            // keeping the ratio here and multiplying first maximizes accuracy and minimizes rounding in the case of small vault values
            argData.shares = fundSplit.funds * vaultValue / vaultSharesOutstanding;
        }

        // mint some shares (accounting before transfer)
        IVault(msg.sender).mintShares(argData.caller, argData.shares);

        // transfer funds in (will revert if the user attempts to purchase shares they cannot afford)
        IERC20(fixedData.denominationAsset).transferFrom(argData.caller, msg.sender, fundSplit.funds);

        // transfer fees
        IERC20(fixedData.denominationAsset).transferFrom(argData.caller, msg.sender, fundSplit.fees);

        // emit the event that some shares were minted at some price
        emit TransferLib.SharesRedeemed(argData.shares, fundSplit.funds);
    }

    // unwind function --> transfer the assets back
    function unwind(uint256 _argIndex, bytes memory _variableArgs) external {
        // get the funds from the args (this is a required input to transfer --> more exact to calculate shares out)
        TransferLib.VariableArgData memory argData = abi.decode(_variableArgs, (TransferLib.VariableArgData));

        // get the fixed data
        TransferLib.FixedArgData memory fixedData = stepData[msg.sender][_argIndex];

        // calculate the number of funds per share --> get the value of the vault and shares outstanding
        uint256 vaultValue = IGAValuer(GAValuer).getVaultValue(msg.sender, fixedData.denominationAsset);
        uint256 vaultSharesOutstanding = IERC20(msg.sender).totalSupply();

        // if the value per share is more than the value per share calculated, send more cash
        uint256 fundsImplied = argData.shares * vaultValue / vaultSharesOutstanding;
        if (argData.funds <= fundsImplied) {
            argData.funds = fundsImplied;
        }
        // else, revert with insufficient shares
        else {
            revert TransferLib.InsufficientShares();
        }

        // split the funds for the user and the protocol fees
        TransferLib.Distribution memory fundSplit = _splitFunds(argData.funds);

        // burn some shares (the fact that they have these shares is validated in the ERC20 contract)
        IVault(msg.sender).burnShares(argData.caller, argData.shares);

        // push the funds from the vault to the user (should be done in generalist function)
        _sendFunds(argData.caller, fundSplit.funds, fixedData.denominationAsset);

        // transfer fees (should be done in generalist function)
        _sendFunds(feeCollector, fundSplit.fees, fixedData.denominationAsset);
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
        fundSplit.fees = IFeeController(feeController).calculateFee(_funds, msg.sender);

        // get the remaining purchasing power
        fundSplit.funds = _funds - fundSplit.fees;

        // return this information back to the caller
        return(fundSplit);
    }

    // send funds (need to encode and send with ERC20)
    // can get the denomination asset from the msg.sender
    // vault has a reentrancy guard to prevent callbacks
    function _sendFunds(address _recipient, uint256 _amount, address _denominationAsset) internal {
        // encode the ERC20 transfer
        bytes memory transferData = abi.encodeCall(IERC20.transfer, (_recipient, _amount));

        // send the transfer
        bytes memory returnData = IVault(msg.sender).execute(_denominationAsset, transferData);

        bool transferSuccess = abi.decode(returnData, (bool));

        // revert if this transfer has not been executed
        if (!transferSuccess) revert TransferLib.TransferFailed();
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
