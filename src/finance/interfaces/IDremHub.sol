// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IDremHub {
    /**
     *  Invalid step parameters passed in
     */
    error InvalidParam();

    /**
     *  Step was not passed in with encoded args
     */
    error InvalidStep();

    /**
     * Passed in Vault Deployer address is not a contract
     */
    error InvalidVaultDeployerAddress();

    /**
     *  Step is already whitelisted
     */
    error StepAlreadyWhitelisted();

    /**
     *  Non-whitelisted step cannot be removed
     */
    error StepNotWhitelisted();

    /**
     *  'isTradingnAllowed' is set to false
     */
    error TradingDisabled();

    function addWhitelistedStep(DataTypes.StepInfo calldata, bytes calldata) external;

    function isStepWhitelisted(DataTypes.StepInfo calldata, bytes calldata) external view returns (bool);

    function setGlobalTrading(bool) external;

    function setProtocolState(DataTypes.ProtocolState) external;

    function setVaultDeployer(address) external;

    function removeWhitelistedStep(DataTypes.StepInfo calldata, bytes calldata) external;

    function deployVault() external;

    function dremHubBeforeTransferHook() external view;

    function getProtocolState() external view returns (DataTypes.ProtocolState);
}
