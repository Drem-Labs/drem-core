// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {DremERC20} from "../../base/DremERC20.sol";
import {IDremHub} from "../../interfaces/IDremHub.sol";
import {Errors} from "../../libraries/Errors.sol";
import {StateAware} from "../../base/StateAware.sol";

/**
 *   INVARIANTS
 *   1. steps[] and stepsEncodedArgs[] must always be the same length
 */

contract Vault is IVault, DremERC20, ReentrancyGuard {
    // DREM_HUB is an immutable variable.  It is stored in runtime code
    // Therefore, accessible by proxies

    uint256 constant MAX_STEPS = 10;

    DataTypes.StepInfo[] steps;
    bytes[] fixedEncodedArgsPerStep;
    address[] vaultAssets;

    constructor(address _dremHub) DremERC20(_dremHub) {
        _disableInitializers();
    }

    // modifier to check if the hub allows interaction from a particular contract
    modifier onlyHubAllowed() {
        // check the hub to see if the sender is an allowed contract
        if (msg.sender != address(DREM_HUB)) revert Errors.MsgSenderIsNotHub();
        _;
    }

    /**
     * @param _name Name of the vault
     * @param _symbol Symbol for the ERC20
     */
    // init should not emit an event -- Fund deployer should
    // each steps need fixed encoded data and variable encoded data
    function init(
        address caller,
        string calldata _name,
        string calldata _symbol,
        DataTypes.StepInfo[] calldata _steps,
        bytes[] calldata _encodedArgsPerStep
    ) external initializer {
        if(_steps.length == 0 || _encodedArgsPerStep.length == 0) revert Errors.EmptyArray();
        if (_steps.length != _encodedArgsPerStep.length) revert Errors.StepsAndArgsNotSameLength();
        __ERC20_init(_name, _symbol);
        _validateSteps(_steps, _encodedArgsPerStep);
        _addSteps(_steps);
    }

    function mintShares(address _to, uint256 _shareAmount) external onlyHubAllowed {
        // call the internal mint function to send shares to the designated address
        _mint(_to, _shareAmount);
    }

    function burnShares(address _to, uint256 _shareAmount) external onlyHubAllowed {
        // call the internal burn frunction to burn the shares of the disignated address
        _burn(_to, _shareAmount);
    }

    // need to be able to call an execute function from steps
    // this is really for interacting with other contracts, not this one and it's ERC20 attributes
    function execute(address _to, bytes calldata data) external onlyHubAllowed returns (bytes memory) {
        (bool success, bytes memory returnBytes) = _to.call(data);

        if (!success) revert CallFailed();

        return (returnBytes);
    }

    // execute steps forward, needs to verify the sender
    function windSteps() external nonReentrant {

    }

    // execute steps backwards, needs to verify the sender
    function unwindSteps() external nonReentrant {

    }

    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external {}

    function getSteps() external view returns (DataTypes.StepInfo[] memory) {
        return steps;
    }

    function _validateSteps(DataTypes.StepInfo[] calldata _steps, bytes[] calldata _encodedArgsPerStep) internal view {
        if (_steps.length > MAX_STEPS || _steps.length == 0) revert Errors.InvalidNumberOfSteps();

        for (uint256 i; i < _steps.length;) {
            _validateStep(_steps[i], _encodedArgsPerStep[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _validateStep(DataTypes.StepInfo calldata _step, bytes memory _encodedArgs) internal view {
        if (!(DREM_HUB.isStepWhitelisted(_step, _encodedArgs))) revert Errors.StepNotWhitelisted();
    }

    function _addSteps(DataTypes.StepInfo[] calldata _steps) internal {
        for (uint256 i; i < _steps.length;) {
            steps.push(_steps[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _executeSteps() internal {}
}
