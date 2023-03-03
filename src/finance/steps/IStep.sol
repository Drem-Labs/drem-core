// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IStep {
    // not able to make changes as the owner
    error NotHubOwner();

    // initialize the step (unknown amount of bytes --> must be decoded)
    function init(bytes calldata encodedArgs) external;

    // wind and unwind the step to move forwards and backwards
    // there should really not be
    function wind(bytes calldata encodedArgs) external;
    function unwind(bytes calldata encodedArgs) external;
}

