// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IGAValuer {
    // Need automatic way to add derivative
    function getVaultValue(address vault, address denominationAsset) external view returns (uint256);
}

