// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (
            ,
            /* uint80 roundId */ int256 answer,
            ,
            ,

        ) = /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/ priceFeed
                .latestRoundData();
        // ETH/USD rate in 18 digits
        return uint256(answer * 1e10); // to convert to 18 decimals
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
