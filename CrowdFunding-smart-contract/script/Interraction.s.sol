// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {CrowdFunding} from "src/CrowdFunding.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract FundCrowdFunding is Script {
    uint256 constant FUND_AMOUNT = 1 ether;

    function fundCrowdfunding(address mostRecentCrowdFunding) public {
        vm.startBroadcast();
        CrowdFunding(payable(mostRecentCrowdFunding)).contribute{
            value: FUND_AMOUNT
        }();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentCrowdFunding = DevOpsTools.get_most_recent_deployment(
            "CrowdFunding",
            block.chainid
        );
        fundCrowdfunding(mostRecentCrowdFunding);
    }
}

contract WithdrawCrowdFunding is Script {
    function withdrawFromCrowdFunding(address mostRecentCrowdFunding) public {
        vm.startBroadcast();
        CrowdFunding(payable(mostRecentCrowdFunding)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentCrowdFunding = DevOpsTools.get_most_recent_deployment(
            "CrowdFunding",
            block.chainid
        );
        withdrawFromCrowdFunding(mostRecentCrowdFunding);
    }
}
