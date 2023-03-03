// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

library TransferLib {
    // errors
    error NotDenominationAsset();

    // struct for what the Fixed Args will be
    struct FixedArgData {
        address denominationAsset;
    }
}
