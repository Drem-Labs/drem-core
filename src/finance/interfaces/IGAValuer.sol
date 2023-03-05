// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IGAValuer {
    function getVaultPrice(address _vault, address _denominationAsset) external view returns(uint256);
}
