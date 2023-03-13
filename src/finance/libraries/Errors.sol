// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

library Errors {
/////////////////////////
///   Global Errors   ///
/////////////////////////

/**
*  Asset is not supported (i.e. does not have an aggregator in Price Aggregator)
*/
error AssetNotSupported();

/**
 * Empty array
 */
error EmptyArray();

/**
*  Non-whitelisted step cannot be removed
*/
error StepNotWhitelisted();

/**
*  Input is address(0)
*/
error ZeroAddress();

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

/**
* msg.sender is not the Drem Hub
*/
error MsgSenderIsNotHub();

/**
* Invalid number of steps
*/
error InvalidNumberOfSteps();

/**
*   
 */
error InvalidStepsLength();

/**
 * Signature Checking --> deadlines & signer
*/
error DeadlineExceeded();
error InvalidSignature();

/**
* Steps array and args array is not the same length
*/
error StepsAndArgsNotSameLength();

////////////////////////////
///   Price Aggregator   ///
////////////////////////////

error InvalidAggregatorRate();
error InvalidConversion();
error InvalidAssetArrays();
error InvalidInputArrays();
error InvalidOutputAsset();
error StaleUSDRate();
error StaleEthRate();

////////////////////////////
///    Asset Registry    ///
////////////////////////////

error AssetAlreadyDenominationAsset();
error AssetNotDenominationAsset();
error AssetAlreadyWhitelisted();
error AssetNotWhitelisted();
}
