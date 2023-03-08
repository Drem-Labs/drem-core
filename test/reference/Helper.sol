// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

abstract contract Helper {
    /**
     * Drem Hub
     */
    bytes ANY_CALL = bytes("DremHub.ANY_CALL");
    bytes32 constant ANY_CALL_HASH = 0x6d1d2d8a4086e5e1886934ed17d0fea24fea45860e94b9c1d77a6a38407e239b;

    /**
     * Price Aggregator
     */
    // uint256 constant STALE_USD_PRICE_LIMIT = 30;
    // uint256 constant STALE_ETH_PRICE_LIMIT = 24 hours;

    /**
     * Token addresses
     */
    address constant AAVE_ADDRESS = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
    address constant DAI_ADDRESS = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address constant USDC_ADDRESS = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant USDT_ADDRESS = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address constant WMATIC_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
}
