// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {BaseStep} from "../../BaseStep.sol";
import {TransferLib} from "./TransferLib.sol";

contract TransferStep is BaseStep {
    // add whatever assets are allowed as denomination assets
    mapping(address => bool) public denominationAssets;

    // keep all the stepData
    mapping(address => mapping(uint256 => TransferLib.FixedArgData)) public stepData;

    // valuer
    address public GAValuer;

    // entrance/exit fees
    TransferLib.FeeData public fees;

    // constructor --> set the GAValuer
    constructor(address _dremHub, address _GAValuer, TransferLib.FeeData memory _fees) BaseStep(_dremHub) {
        _setGAValuer(_GAValuer);
        _setFees(_fees);
    }

    // initialized with the denomination asset and the tracked assets
    function init(uint256 _argIndex, bytes calldata _fixedArgs) external {
        // turn the fixed args into a useful struct
        TransferLib.FixedArgData memory fixedArgData = abi.decode(_fixedArgs, (TransferLib.FixedArgData));

        // validate the denomination asset
        if (!denominationAssets[fixedArgData.denominationAsset]) revert TransferLib.NotDenominationAsset();

        // store the stepData (can store to msg.sender to ensure that only the vaults can interact with this)
        stepData[msg.sender][_argIndex] = fixedArgData;
    }

    // wind function --> transfer some assets
    function wind(uint256 _argIndex, bytes memory _variableArgs) external {
        // get the shares from the args

        // calculate the number of funds per share --> get the value of the vault

        // figure out who the caller is

        // transfer shares in

        // mint some shares

        // assume that the funds are in the wallet (not in the vault) --> transfer them into the vault

        // transfer fees

    }

    // unwind function --> transfer the assets back
    function unwind(uint256 _argIndex, bytes memory _variableArgs) external {
        // get the shares from the args

        // calculate the number of funds per share --> get the value of the vault

        // figure out who the caller is

        // ensure that they are allowed to liquidate these many shares

        // burn some shares

        // push the funds from the vault to the user

        // transfer fees

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

    // set the valuer (internal)
    function _setGAValuer(address _GAValuer) internal {
        GAValuer = _GAValuer;
    }

    // set the step fees (internal)
    function _setFees(TransferLib.FeeData memory _fees) internal {
        fees = _fees;
    }
}
