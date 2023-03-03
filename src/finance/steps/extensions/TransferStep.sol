// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {BaseStep} from "../BaseStep.sol";

contract TransferStep is BaseStep {
    // errors
    error NotDenominationAsset();

    // struct for what the Fixed Args will be
    struct FixedArgData {
        address denominationAsset;
    }

    // add whatever assets are allowed as denomination assets
    mapping(address => bool) denominationAssets;

    // keep all the stepData
    mapping(address => mapping(uint256 => FixedArgData)) public stepData;

    // initialized with the denomination asset and the tracked assets
    function init(uint256 _argIndex, bytes calldata _fixedArgs) external {
        // turn the fixed args into a useful struct
        fixedArgData = abi.decode(_fixedArgs, (FixedArgData));

        // validate the denomination asset
        if (!denominationAssets[fixedArgData.denominationAsset]) revert NotDenominationAsset();

        // store the stepData (can store to msg.sender to ensure that only the vaults can interact with this)
        stepData[msg.sender][_argIndex] = fixedArgData;
    }
}
