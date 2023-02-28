// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

contract DremHub {
//     mapping(address => address) vaultToComptroller:  keeps track of the vault’s given comptroller
// bytes32 ANY_CALL
// keccak256(‘
// mapping(bytes32 => bytes32 => bool) whitelistedStep
// keccak256(contractAddress, functionSelector) => keccack256(encodedArgs) => bool
// Get around function variability via ANY_CALL: 
// If whitelistedStep[keccak256(contractAddress, functionSelector)] [ANY_CALL] is true, enable any encoded args
// Else, whitelistedStep[keccak256(contractAddress, functionSelector)] [keccak256(encodedArgs)] must be true 
// Allow for global trading variable
// Will consider whether or not to have managers control transferability

// keccak256(contractAddress, functionSelector) => keccak25
mapping(bytes32 => mapping(bytes32 => bool)) whitelistedStep;

}