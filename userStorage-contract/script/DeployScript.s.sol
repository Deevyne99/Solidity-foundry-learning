// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {UserStorage} from "../src/UserStorage.sol";

contract DeployScript is Script {
    function run() external returns (UserStorage) {
        vm.startBroadcast();
        UserStorage userStorage = new UserStorage();
        vm.stopBroadcast();
        return userStorage;
    }
}
