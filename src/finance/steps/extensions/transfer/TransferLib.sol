// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

library TransferLib {
    // errors
    error NotDenominationAsset();

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
        uint256 shares;
    }
}
