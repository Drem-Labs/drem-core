// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IStep {
    // initialize the step (unknown amount of bytes --> must be decoded)
    function init(uint256 argIndex, bytes calldata fixedArgs) external;

    // wind and unwind the step to move forwards and backwards
    // there should really not be
    function wind(uint256 argIndex, bytes memory variableArgs) external;
    function unwind(uint256 argIndex, bytes memory variableArgs) external;
}
