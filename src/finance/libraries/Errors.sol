// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;


/////////////////////////
///   Global Errors   ///
/////////////////////////

library Errors {

/**
*  Non-whitelisted step cannot be removed
*/
error StepNotWhitelisted();

////////////
/// Base ///
////////////

/**
 * Msg sender is not hub owner
 */
error NotHubOwner();

/**
 * Protocol is paused or frozen
 */
error ProtocolPausedOrFrozen();

/**
 * Protocol is frozen 
 */
error ProtocolFrozen();

//////////////////
///  Drem Hub  ///
//////////////////

/**
*  Invalid step parameters passed in
*/
error InvalidParam();

/**
*  Step was not passed in with encoded args
*/
error InvalidStep();

/**
* Passed in Vault Deployer address is not a contract
*/
error InvalidVaultDeployerAddress();

/**
*  Step is already whitelisted
*/
error StepAlreadyWhitelisted();

/**
*  'isTradingnAllowed' is set to false
*/
error TradingDisabled();

/////////////////
///   Vault   ///
/////////////////

error InvalidNumberOfSteps();
error InvalidStepsLength();
error StepsAndArgsNotSameLength();

}