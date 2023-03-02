// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IOwnable {
    // just need access to the owner function
    function owner() external returns(address);
}
