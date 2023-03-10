// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

// To Do: Order alphabetically
library DataTypes {
    /////////////////////////////
    ///   Global Data Types   ///
    ////////////////////////////

    // basic step routing information
    struct StepInfo {
        address interactionAddress;
        bytes fixedArgData;
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
     *  Disabled: No functionality
     *  Deprecated: Unwind existing strategies
     *  Legacy: Wind and unwind existing strategies
     *  Enabled: Wind, unwind, create new strategies
     */
    enum StepState {
        Disabled,
        Deprecated,
        Legacy,
        Enabled
    }

    ///////////////////////////////////////
    ///   Price Aggregator Data Types   ///
    ///////////////////////////////////////

    enum RateAsset {
        USD,
        ETH
    }

    struct SupportedAssetInfo {
        AggregatorV3Interface aggregator;
        RateAsset rateAsset;
        uint256 units;
    }

    /////////////////////////////////////
    ///   Vault Deployer Data Types   ///
    /////////////////////////////////////

    struct DeploymentInfo {
        address demonminationAsset;
        uint256 inputAmount;
        string name;
        string symbol;
        StepInfo[] steps;
    }
}
