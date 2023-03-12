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

    // controls how many fees are paid and to where
    address feeController;

    // constructor --> set the GAValuer
    constructor(address _dremHub, address _feeController) BaseStep(_dremHub) {
        _setFeeController(_feeController);
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

        // transfer funds in (will revert if the user attempts to purchase shares they cannot afford)
        // this is different than sending funds, as that happens from the vault
        bool success;
        success = IERC20(fixedData.denominationAsset).transferFrom(argData.caller, msg.sender, fundSplit.funds);
        if (!success) revert TransferLib.TransferFailed();

        // transfer fees
        success = IERC20(fixedData.denominationAsset).transferFrom(argData.caller, IFeeController(feeController).collector(), fundSplit.fees);
        if (!success) revert TransferLib.TransferFailed();

        // emit the event that some shares were minted at some price
        emit TransferLib.SharesRedeemed(argData.shares, fundSplit.funds);
    }

    // unwind function --> transfer the assets back
    function unwind(uint256 _argIndex, bytes memory _variableArgs) external {
        // get the funds from the args (this is a required input to transfer --> more exact to calculate shares out)
        TransferLib.VariableArgData memory argData = abi.decode(_variableArgs, (TransferLib.VariableArgData));

        // get the fixed data
        TransferLib.FixedArgData memory fixedData = stepData[msg.sender][_argIndex];

        // split the funds for the user and the protocol fees
        TransferLib.Distribution memory fundSplit = _splitFunds(argData.funds);

        // push the funds from the vault to the user (should be done in generalist function)
        _sendFunds(argData.caller, fundSplit.funds, fixedData.denominationAsset);

        // transfer fees (should be done in generalist function)
        _sendFunds(IFeeController(feeController).collector(), fundSplit.fees, fixedData.denominationAsset);
    }

    // set allowed denomination assets (must be very liquid, not just tracked)
    function setDenominationAssst(address _assetAddress, bool _assetAllowed) external onlyHubOwner {
        denominationAssets[_assetAddress] = _assetAllowed;
    }

    // set the fee controller
    function setFeeController(address _feeController) external onlyHubOwner {
        _setFeeController(_feeController);
    }

    // get the funds split
    function _splitFunds(uint256 _funds) internal pure returns(TransferLib.Distribution memory) {
        // allocate some memory to the distribution
        TransferLib.Distribution memory fundSplit;

        // get the fee that the user will incur (will be handled by the fee controller)
        // save this for later, when we build a fee controller
        // fundSplit.fees = IFeeController(feeController).calculateFee(_funds, msg.sender);
        fundSplit.fees = 0;

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

    // set the fee controller (internal)
    function _setFeeController(address _feeController) internal {
        feeController = _feeController;
    }
}
