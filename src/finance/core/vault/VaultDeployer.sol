// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Events} from "../../libraries/Events.sol";
import {StateAware} from "../../base/StateAware.sol";
import {Vault} from "./Vault.sol";

contract VaultDeployer is StateAware, UUPSUpgradeable {
    using Clones for address;

    address private vaultImplementation;

    mapping(address => uint256) private nextVaultIdByAddress;
    mapping(address => mapping(uint256 => address)) private addressToIndexToVault;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    constructor(address _dremHub) StateAware(_dremHub) {}

    function init() external initializer {
        vaultImplementation = address(new Vault(address(DREM_HUB)));
    }

    // Question: Are we doing gas relaying?
    // If so, we need to get msg.sender that is compliant with EIP2771 

    /**
     * @notice Deploys a new vault with given strategies
     * Uses ERC-1167 minimal proxies: https://eips.ethereum.org/EIPS/eip-1167 
     * @param _name The name of the vault
     * @param _symbol The symbol for the vault shares
     * @param _steps The steps to use in the vault
     * @param _fixedArgDataPerStep The fixed argument data to use for each step in the vault
     * @param _variableArgDataPerStep The variable argument data used in the initial wind
     * @return The address of the newly created vault
     */
    function deployVault(
        string calldata _name,
        string calldata _symbol,
        DataTypes.StepInfo[] calldata _steps,
        bytes[] calldata _fixedArgDataPerStep,
        bytes [] calldata _variableArgDataPerStep
    ) external returns (address) {
        // Deploy proxy
        address _vault = vaultImplementation.clone();
        
        // Init
        Vault(_vault).init(
            _name,
            _symbol,
            _steps,
            _fixedArgDataPerStep
        );

        // Wind
        // Can't do right now...

        // Emit event
        emit Events.NewVaultDeployed(_vault);

        return _vault;
    }

    // Can actually manually be done on the frontend but requires multiple calls...
    function getAllVaultsForAddress(address _address) external view returns (address[] memory) {
        uint256 _totalVaultsOfAddress = nextVaultIdByAddress[_address];

        address[] memory _vaults = new address[](_totalVaultsOfAddress);

        for(uint256 i; i < _totalVaultsOfAddress; ) {
            _vaults[i] = addressToIndexToVault[_address][i];
            unchecked{++i;}
        }

        return _vaults;
    }

    function getTotalVaultsByAddress(address _address) external view returns(uint256) {
        return nextVaultIdByAddress[_address];
    }

    function getVaultByIndex(uint256 _index, address _address) external view returns(address) {
        return addressToIndexToVault[_address][_index];
    }

    function getVaultImplementation() external view returns (address) {
        return vaultImplementation;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyHubOwner {}
}
