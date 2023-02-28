// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IDremHub {

    /**
     *  'isTradingnAllowed' is set to false
     */
    error TradingDisabled();

    /**
     *  Invalid parameter passed into function
     */
    error InvalidParam();

    function addWhitelistedStep() external;

}