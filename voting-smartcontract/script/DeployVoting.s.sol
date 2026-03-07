// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Script} from "forge-std/Script.sol";
import {Ballot} from "../src/Voting.sol";

contract DeployVoting is Script {
    function run() external returns (Ballot) {
        vm.startBroadcast();
        string[] memory proposals = new string[](3);
        proposals[0] = "Proposal 1";
        proposals[1] = "Proposal 2";
        proposals[2] = "Proposal 3";
        Ballot ballot = new Ballot(proposals, 1 days);
        vm.stopBroadcast();
        return ballot;
    }
}
