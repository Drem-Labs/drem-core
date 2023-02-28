// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

library Events {

    /**
     * @dev Emitted when whitelisted step is added
     * 
     * @param interactionAddress the contract address associated with the step
     * @param functionSelector the function selector associated with the step
     * @param encodedArgs the encoded args 
     */ 
    event WhitelistedStepAdded(address interactionAddress, bytes4 functionSelector, bytes encodedArgs);
    
    /**
     * @dev Emitted when whitelisted step is removed
     * 
     * @param interactionAddress the contract address associated with the step
     * @param functionSelector the function selector associated with the step
     * @param encodedArgs the encoded args 
     */ 
    event WhitelistedStepRemoved(address interactionAddress, bytes4 functionSelector, bytes encodedArgs);

    event FundDeployerSet();

    event GlobalStateUpdated();

    event GlobalTradingSet(bool setting);
}