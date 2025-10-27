// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CrowdFunding} from "src/CrowdFunding.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCrowdFunding is Script {
    function run() external returns (CrowdFunding) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        CrowdFunding crowdfunding = new CrowdFunding(ethUsdPriceFeed, 12);
        vm.stopBroadcast();
        return crowdfunding;
    }
}
