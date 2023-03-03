// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IStep {
    // not able to make changes as the owner
    error NotHubOwner();

    // initialize the step (unknown amount of bytes --> must be decoded)
    function init(uint256 _argIndex, bytes calldata _fixedArgs) external;

    // wind and unwind the step to move forwards and backwards
    // there should really not be
    function wind(uint256 _shares) external;
    function unwind(uint256 _shares) external;
}

