// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

contract DremHub {

    // keccak256(contractAddress, functionSelector) => keccak256(encodedArgs) => bool
    mapping(bytes32 => mapping(bytes32 => bool)) whitelistedStep;

    // keccak256('DremHub.ANY_CALL')
    bytes32 private constant ANY_CALL = 0x6d1d2d8a4086e5e1886934ed17d0fea24fea45860e94b9c1d77a6a38407e239b;

    bool public isTradingAllowed;

    function setGlobalTrading(bool _isTradingAllowed) external {}

    function addStep() external {}
}