// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";


// contract untuk mendeploy raffle
contract DeployRaffle is Script{
    function run() external returns(Raffle) {  
        HelperConfig helperConfig = new HelperConfig(); // memanggil contract HelperConfig
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit) = helperConfig.ActiveNetworkConfig();  // mengambil variable dari ActiveNetworkConfig
        
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();
        return raffle;

    }
}
