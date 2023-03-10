// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";
import {IOwnable} from "./IOwnable.sol";

interface IDremHub {
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
