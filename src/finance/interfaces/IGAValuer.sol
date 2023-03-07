// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IGAValuer {
    function getVaultValue(address vault, address denominationAsset) external view returns(uint256);
}
