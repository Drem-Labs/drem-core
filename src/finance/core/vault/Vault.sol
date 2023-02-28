// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IVault} from "../../interfaces/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";

contract Vault is IVault, ERC20 {
    // Need to make this ERC20 Upgradeable...
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

    }

    function init() external {}

    function steps() external view returns(DataTypes.StepInfo[] memory) {

    }

    function mintShares(uint256 _shareAmount) external {

    }

    function burnShares(uint256 _shareAmount) external {

    }

    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external {

    }
}