// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DataTypes} from "./DataTypes.sol";

library Events {
    /////////////////////////////
    //     Drem Hub Events     //
    /////////////////////////////

    /**
     * @dev Emitted when whitelisted step is added
     *
     * @param interactionAddress the contract address associated with the step
     * @param functionSelector the function selector associated with the step
     * @param encodedArgs the encoded args
     */
    event WhitelistedStepAdded(address interactionAddress, bytes4 functionSelector, bytes encodedArgs);

    /**
     * @dev Emitted when whitelisted step is removed
     *
     * @param interactionAddress the contract address associated with the step
     * @param functionSelector the function selector associated with the step
     * @param encodedArgs the encoded args
     */
    event WhitelistedStepRemoved(address interactionAddress, bytes4 functionSelector, bytes encodedArgs);

    /**
     *
     */
    event FundDeployerSet();

    /**
     * @dev Emitted when protocol state is set
     *
     * @param _state the new protocol state
     */
    event ProtocolStateSet(DataTypes.ProtocolState _state);

    /**
     * @dev Emitted when global trading is set
     *
     * @param setting the new setting
     */
    event GlobalTradingSet(bool setting);

    /////////////////////////////////////
    //     Price Aggregator Events     //
    /////////////////////////////////////

    event EthToUSDAggregatorSet(AggregatorV3Interface ethToUSDAggregator);

    event MaticToUSDAggregatorSet(AggregatorV3Interface maticToUSDAggregator);

    /**
     *
     */
    event SupportedAssetAdded(address asset, AggregatorV3Interface aggregator, DataTypes.RateAsset rateAsset);

    /**
     *
     */
    event SupportedAssetRemoved(address asset, AggregatorV3Interface aggregator, DataTypes.RateAsset rateAsset);
}
