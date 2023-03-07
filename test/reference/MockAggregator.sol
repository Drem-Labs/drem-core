// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockAggregator is AggregatorV3Interface {

    uint8 private constant DECIMALS = 8;
    int256 aggregatorAnswer;
    uint256 lastUpdated;
    
    constructor() {
        lastUpdated = block.timestamp;
    }

    function setAnswer(int256 _newAnswer) external {
        aggregatorAnswer = _newAnswer;
    }
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function description() external pure returns (string memory) {
        return "";
    }

  function version() external pure returns (uint256) {
        return 0;
  }

  function getRoundData(uint80) external view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    ) {
        return (0, aggregatorAnswer, 0, lastUpdated, 0);
    }

  function latestRoundData()
    external
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    ) {
        return (0, aggregatorAnswer, 0, lastUpdated, 0);
    }
} 