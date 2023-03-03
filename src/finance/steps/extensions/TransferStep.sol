// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {BaseStep} from "../BaseStep.sol";

contract TransferStep is BaseStep {
    // struct for what the Fixed Args will be
    struct FixedArgData {
        address denominationAsset;
        address[] trackedAssets;
    }

    // add whatever assets are allowed as denomination assets

    // initialized with the denomination asset and the tracked assets
    function init(uint256 _argIndex, bytes calldata _fixedArgs) external {
        // turn the fixed args into a useful struct
        fixedArgData = abi.decode(_fixedArgs, (FixedArgData));

        // validate the denomination asset

    }
}
