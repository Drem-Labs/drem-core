// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IVault} from "../../interfaces/IVault.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {DremERC20} from "../../base/DremERC20.sol";
import {Errors} from "../../libraries/Errors.sol";
import {StateAware} from "../../base/StateAware.sol";

/**
 *   INVARIANTS
 *   1. steps[] and stepsEncodedArgs[] must always be the same length
 */

contract Vault is IVault, DremERC20  {
    // Need to make this ERC20 Upgradeable...
    // DREM_HUB is an immutable variable.  It is stored in runtime code
    // Therefore, accessible by proxies

    uint256 constant MAX_STEPS = 10;

    DataTypes.StepInfo[] private steps;

    constructor(address _dremHub) DremERC20(_dremHub){}

    /**
     * @param _name Name of the vault
     * @param _symbol Symbol for the ERC20
     */
     // init should not emit an event -- Fund deployer should
    function init( 
        address caller,
        string calldata _name,
        string calldata _symbol,
        DataTypes.StepInfo[] calldata _steps,
        bytes[] calldata _encodedArgsPerStep ) external initializer {
        if (_steps.length != _encodedArgsPerStep.length) revert Errors.StepsAndArgsNotSameLength();
        __ERC20_init(_name, _symbol);
        _validateSteps(_steps, _encodedArgsPerStep);
        _addSteps(_steps);
    }

    function mintShares(uint256 _shareAmount, address _to) external {
        // Execute steps...
    }

    function burnShares(uint256 _shareAmount, address _to) external {
        // Need certain withdrawl steps...
    }

    // Deposits and withdrawls may need to be moved to the controller depending on whether or not migrations are possible

    function deposit() external {}

    function depositFor() external {}

    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external {}

    function withdrawFor() external{}

    function getSteps() external view returns (DataTypes.StepInfo[] memory) {
        return steps;
    }

    function _validateSteps(DataTypes.StepInfo[] calldata _steps, bytes[] calldata _encodedArgsPerStep) internal view {
        
        if(_steps.length > MAX_STEPS || _steps.length == 0) revert Errors.InvalidNumberOfSteps();

        for (uint256 i; i < _steps.length; ){
            _validateStep(_steps[i], _encodedArgsPerStep[i]);
            unchecked{++i;}
        }
    }

    function _validateStep(DataTypes.StepInfo calldata _step, bytes memory _encodedArgs) internal view{
        if(!(DREM_HUB.isStepWhitelisted(_step, _encodedArgs))) revert Errors.StepNotWhitelisted();
    }

    function _addSteps(DataTypes.StepInfo[] calldata _steps) internal {
        for (uint256 i; i < _steps.length; ) {
            steps.push(_steps[i]);
            unchecked{++i;}
        }
    }

    function _executeSteps() internal {}
}
