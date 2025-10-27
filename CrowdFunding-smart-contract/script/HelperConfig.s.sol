// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {CrowdFunding} from "../src/CrowdFunding.sol";
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // CrowdFunding crowdFunding;

    // function run() external {
    //     vm.startBroadcast();
    //     crowdFunding = new CrowdFunding();
    //     vm.stopBroadcast();
    // }
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address crowdFunding;
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            crowdFunding: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });

        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.crowdFunding != address(0)) {
            return activeNetworkConfig; // already deployed return it
        }
        vm.startBroadcast();
        // CrowdFunding crowdFunding = new CrowdFunding();

        //Note remove magic numbers
        // uint8 DECIMALS = 18;
        // int256 INITIAL_ANSWER = 2000e8;
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );

        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            crowdFunding: address(mockV3Aggregator)
        });
        return anvilConfig;
    }
}
