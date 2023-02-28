// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Ownable2StepUpgradeable} from "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol"; 
import {IDremHub} from "../interfaces/IDremHub.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Events} from "../libraries/Events.sol";

// Initializable is inherited from Ownable2StepUpgradeable
contract DremHub is Ownable2StepUpgradeable, UUPSUpgradeable, IDremHub {

    // keccak256('DremHub.ANY_CALL')
    bytes32 private constant ANY_CALL_HASH = 0x6d1d2d8a4086e5e1886934ed17d0fea24fea45860e94b9c1d77a6a38407e239b;
                                        
    // keccak256(contractAddress, functionSelector) => keccak256(encodedArgs) => bool
    mapping(bytes32 => mapping(bytes32 => bool)) private whitelistedSteps;

    bool private isTradingAllowed;

    address private vaultDeployer;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

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

    // Need to verify with Drem team about global state
    function setGlobalState() external onlyOwner {}

    function setVaultDeployer(address _vaultDeployer) external onlyOwner{
        if(_vaultDeployer.code.length == 0) revert InvalidVaultDeployerAddress();
        vaultDeployer = _vaultDeployer;
    }

    function addWhitelistedStep(DataTypes.StepInfo calldata _step, bytes calldata _encodedArgs) external onlyOwner {
        _setWhitelistedStep(_step, _encodedArgs, true);
        emit Events.WhitelistedStepAdded(_step.interactionAddress, _step.functionSelector, _encodedArgs);
    }

    function removeWhitelistedStep(DataTypes.StepInfo calldata _step, bytes calldata _encodedArgs) external onlyOwner {
        _setWhitelistedStep(_step, _encodedArgs, false);
        emit Events.WhitelistedStepRemoved(_step.interactionAddress, _step.functionSelector, _encodedArgs); 
    }

    // Need to verify with Drem team if vault's are upgradeable
    // If not, there is no need for this function
    // Function would be used to add to the comptroller => vault mapping
    function deployVault() external onlyVaultDeployer{}

    /***************************
     *    View functions                         
     **************************/

    function dremHubBeforeTransferHook() external view {
        if(!(isTradingAllowed)) revert TradingDisabled();
    }

    function isStepWhitelisted(DataTypes.StepInfo calldata _step, bytes calldata _encodedArgs) external view returns(bool){
        bytes32 _stepHash = _getStepHash(_step);
        bytes32 _encodedArgsHash = keccak256(_encodedArgs);

        return whitelistedSteps[_stepHash][ANY_CALL_HASH] ? true : whitelistedSteps[_stepHash][_encodedArgsHash];
    }

    /***************************
     *    Internal functions                         
     **************************/
    
    /**
     @dev Used for modifier to cut down on bytecode
     */
    function _onlyVaultDeployer() internal {}

    function _setWhitelistedStep(DataTypes.StepInfo calldata _step, bytes calldata _encodedArgs, bool _setting) internal {
        if (_step.interactionAddress == address(0) || _step.functionSelector == bytes4(0)) revert InvalidStep();
        
        bytes32 _stepHash = _getStepHash(_step);
        bytes32 _encodedArgsHash = keccak256(_encodedArgs);

        whitelistedSteps[_stepHash][_encodedArgsHash] = _setting;
    }

    function _getStepHash(DataTypes.StepInfo calldata _step) internal pure returns(bytes32) {
        return keccak256(abi.encode(_step.interactionAddress, _step.functionSelector)); 
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}