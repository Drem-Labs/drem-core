// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

// To Do: Order alphabetically
library DataTypes {
    
    /**
     * Global data types
     */
    
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

    /**
     *  Unpaused: All protocol actions enabled
     *  Paused: Creation of new trade paused.  Copying and exiting trades still possible.
     *  Frozen: Copying and creating new trades paused.  Exiting trades still possible
     */
    enum ProtocolState {
        Unpaused,
        Paused,
        Frozen
    }

    /**
     *  Enabled: Wind, unwind, create new strategies
     *  Legacy: Wind and unwind existing strategies
     *  Deprecated: Unwind existing strategies
     *  Disabled: No functionality
     */
    enum StepState {
        Enabled,
        Legacy,
        Deprecated,
        Disabled
    }

    /**
     *  Price aggregator data types
     */
     
}
