// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

library TransferLib {
    // errors
    error InvalidDenominationAsset();
    error InsufficientFunds();

    // events
    event SharesIssued(uint256 shares, uint256 price);
    event SharesRedeemed(uint256 shares, uint256 price);

    // fee data (int packed)
    struct FeeData {
        uint128 entranceFee;
        uint128 exitFee;
    }

    // struct for what the Fixed Args will be
    struct FixedArgData {
        address denominationAsset;
    }

    // struct for the variable args (really just the shares)
    struct VariableArgData {
        address caller;
        uint256 funds;
        uint256 shares;
    }

    // struct for splitting funds into fees and purchasing power
    struct Distribution {
        uint256 purchase;
        uint256 fee;
    }
}
