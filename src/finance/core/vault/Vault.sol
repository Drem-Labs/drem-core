// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IVault} from "../../interfaces/IVault.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {StateAware} from "../../base/StateAware.sol";
import {DremERC20} from "../../base/DremERC20.sol";

contract Vault is IVault, DremERC20  {
    // Need to make this ERC20 Upgradeable...
    // DREM_HUB is an immutable variable.  It is stored in runtime code
    // Therefore, accessible by proxies
    constructor(address _dremHub) DremERC20(_dremHub){

    }

    function init( 
        string calldata _name,
        string calldata _symbol,
        DataTypes.StepInfo[] calldata _steps) external initializer {
        __ERC20_init(_name, _symbol);
        _validateSteps(_steps);
        _addSteps(_steps);
    }

    function steps() external view returns (DataTypes.StepInfo[] memory) {}

    function mintShares(uint256 _shareAmount) external {}

    function burnShares(uint256 _shareAmount) external {}

    // Deposits and withdrawls may need to be moved to the controller depending on whether or not migrations are possible

    function deposit() external {}

    function depositFor() external {}

    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external {}

    function withdrawFor() external{}

    function _validateSteps(DataTypes.StepInfo[] calldata) internal {}

    function _addSteps(DataTypes.StepInfo[] calldata) internal {}


}
