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

    // set the version, typehash (this is really just for EIP 712 domain hash)
    uint256 constant VERSION = 1;

    // vault accounting
    DataTypes.StepInfo[] steps;
    address[] vaultAssets;

    // signatures
    bytes32 private constant STEP_VAR_DATA_TYPEHASH =
        keccak256("VariableStepData(address owner,bytes[] memory variableStepData,uint256 nonce,uint256 deadline)");
    mapping(address => uint256) private nonces;

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
        if (_steps.length == 0 || _encodedArgsPerStep.length == 0) revert Errors.EmptyArray();
        if (_steps.length != _encodedArgsPerStep.length) revert Errors.StepsAndArgsNotSameLength();
        __ERC20_init(_name, _symbol);
        _validateSteps(_steps);
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

    // Make sure to include input validation..
    function execute(address _to, bytes calldata _data) external onlyHubAllowed returns (bytes memory) {
        (bool success, bytes memory returnBytes) = _to.call(_data);

        if (!success) revert CallFailed();

        return (returnBytes);
    }

    // execute steps forward, needs to verify the sender
    function windSteps(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _owner,
        bytes[] memory _variableStepData,
        uint256 _deadline
    ) external nonReentrant {
        // verify the signer
        _verifySigner(_v, _r, _s, _owner, _variableStepData, _deadline);

        // wind each step
    }

    // execute steps backwards, needs to verify the sender
    function unwindSteps(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _owner,
        bytes[] memory _variableStepData,
        uint256 _deadline
    ) external nonReentrant {
        // verify the signer
        _verifySigner(_v, _r, _s, _owner, _variableStepData, _deadline);

        // unwind each step
    }

    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external {}

    function getSteps() external view returns (DataTypes.StepInfo[] memory) {
        return steps;
    }

    // getter for the domain hash, which will be constant within each vault
    function DOMAIN_HASH() public view returns (bytes32) {
        bytes32 dhash = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(abi.encodePacked(VERSION)),
                block.chainid,
                address(this)
            )
        );

        return dhash;
    }

    // getter for the hash struct
    function getHashStruct(address _owner, bytes[] memory _variableStepData, uint256 _deadline)
        public
        view
        returns (bytes32)
    {
        bytes32 hashStruct =
            keccak256(abi.encode(STEP_VAR_DATA_TYPEHASH, _owner, _variableStepData, nonces[_owner], _deadline));

        return hashStruct;
    }

    function _validateSteps(DataTypes.StepInfo[] calldata _steps) internal view {
        if (_steps.length > MAX_STEPS || _steps.length == 0) revert Errors.InvalidNumberOfSteps();

        for (uint256 i; i < _steps.length;) {
            _validateStep(_steps[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _validateStep(DataTypes.StepInfo calldata _step) internal view {
        if (!(DREM_HUB.isStepWhitelisted(_step))) revert Errors.StepNotWhitelisted();
    }

    function _addSteps(DataTypes.StepInfo[] calldata _steps) internal {
        for (uint256 i; i < _steps.length;) {
            steps.push(_steps[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _verifySigner(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _owner,
        bytes[] memory _variableStepData,
        uint256 _deadline
    ) internal {
        if (_deadline >= block.timestamp) revert Errors.DeadlineExceeded();

        // create the combined hash
        bytes32 _hash =
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_HASH(), getHashStruct(_owner, _variableStepData, _deadline)));

        // get the signer
        address signer = ecrecover(_hash, _v, _r, _s);

        // verify that the signer is the owner (not being done yet, as this requires heavy testing)
        // if ((signer != _owner) || (signer == address(0))) revert Errors.InvalidSignature();

        // increment nonce, let the calling function continue
        ++nonces[_owner];
    }

    function _executeSteps() internal {}
}
