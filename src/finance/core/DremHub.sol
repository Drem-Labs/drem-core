// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Ownable2StepUpgradeable} from "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol"; 
import {IDremHub} from "../interfaces/IDremHub.sol";

// Initializable is inherited from Ownable2StepUpgradeable
contract DremHub is Ownable2StepUpgradeable, UUPSUpgradeable, IDremHub {

    // keccak256('DremHub.ANY_CALL')
    bytes32 private constant ANY_CALL = 0x6d1d2d8a4086e5e1886934ed17d0fea24fea45860e94b9c1d77a6a38407e239b;

    // keccak256(contractAddress, functionSelector) => keccak256(encodedArgs) => bool
    mapping(bytes32 => mapping(bytes32 => bool)) whitelistedStep;

    bool public isTradingAllowed;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    constructor() {
        _disableInitializers();
    }

    function init() external initializer {
        __Ownable2Step_init();
        // Technically unnecessary but good practice...
        __UUPSUpgradeable_init();
    }

    function setGlobalTrading(bool _isTradingAllowed) external onlyOwner {
        if (isTradingAllowed == _isTradingAllowed) revert InvalidParam();
        isTradingAllowed = _isTradingAllowed;
    }

    // Need to verify with Drem team about global state
    function setGlobalState() external onlyOwner {}

    function addWhitelistedStep() external {}

    function dremHubBeforeTransferHook() external view {
        if(!(isTradingAllowed)) revert TradingDisabled();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}