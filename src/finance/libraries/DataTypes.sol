// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library DataTypes {
    // basic step routing information
    struct StepInfo {
        address interactionAddress;
        bytes4 functionSelector;
    }

    // user expectations for the withdrawal assets (can't check with oracles in worst-case)
    // note: the amount is not being stored or used often, so best to keep it as a uint256 in case users have a ton of a bespoke token
    struct AssetExpectation {
        address assetAddress;
        uint256 amount;
    }
}
