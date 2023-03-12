// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Ownable2StepUpgradeable} from "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IDremHub} from "../interfaces/IDremHub.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";

// Initializable is inherited from Ownable2StepUpgradeable
contract DremHub is Ownable2StepUpgradeable, UUPSUpgradeable, IDremHub {
    bool private isTradingAllowed;
    address private vaultDeployer;
    DataTypes.ProtocolState protocolState;

    // just checking if it is a drem-verified step contract
    mapping(address => bool) public whitelistedSteps;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    modifier onlyVaultDeployer() {
        _onlyVaultDeployer();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function init() external initializer {
        __Ownable2Step_init();
        // Technically unnecessary but good practice...
        __UUPSUpgradeable_init();
    }

    function setGlobalTrading(bool _isTradingAllowed) external onlyOwner {
        isTradingAllowed = _isTradingAllowed;
        emit Events.GlobalTradingSet(_isTradingAllowed);
    }

    // Unpaused: Anything is possible!
    // Paused: No new trades can be opened; deposits and withdrawls possible; vault shares transfers turned on
    // Frozen: Nothing is possible except withdrawls;
    function setProtocolState(DataTypes.ProtocolState _state) external onlyOwner {
        protocolState = _state;
        emit Events.ProtocolStateSet(_state);
    }

    function setVaultDeployer(address _vaultDeployer) external onlyOwner {
        if (_vaultDeployer.code.length == 0) revert Errors.InvalidVaultDeployerAddress();
        vaultDeployer = _vaultDeployer;
    }

    function addWhitelistedStep(DataTypes.StepInfo calldata _step) external onlyOwner {
        _setWhitelistedStep(_step, true);
        emit Events.WhitelistedStepAdded(_step.interactionAddress);
    }

    function removeWhitelistedStep(DataTypes.StepInfo calldata _step) external onlyOwner {
        _setWhitelistedStep(_step, false);
        emit Events.WhitelistedStepRemoved(_step.interactionAddress);
    }

    // Need to verify with Drem team if vault's are upgradeable
    // If not, there is no need for this function
    // Function would be used to add to the comptroller => vault mapping
    function deployVault() external onlyVaultDeployer {}

    /**
     *
     *    View functions
     *
     */

    function dremHubBeforeTransferHook() external view {
        if ((!(isTradingAllowed)) || protocolState == DataTypes.ProtocolState.Frozen) revert Errors.TradingDisabled();
    }

    function isStepWhitelisted(DataTypes.StepInfo calldata _step)
        external
        view
        returns (bool)
    {
        return whitelistedSteps[_step.interactionAddress];
    }

    function getProtocolState() external view returns (DataTypes.ProtocolState) {
        return protocolState;
    }

    /**
     *
     *    Internal functions
     *
     */

    /**
     * @dev Used for modifier to cut down on bytecode
     */
    function _onlyVaultDeployer() internal {}

    function _setWhitelistedStep(DataTypes.StepInfo calldata _step, bool _setting)
        internal
    {
        whitelistedSteps[_step.interactionAddress] = _setting;
    }

    function _getStepHash(DataTypes.StepInfo calldata _step) internal pure returns (bytes32) {
        return keccak256(abi.encode(_step.interactionAddress, _step.functionSelector));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
