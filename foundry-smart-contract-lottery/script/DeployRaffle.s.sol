// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../script/Interactions.s.sol";


// contract untuk mendeploy raffle
contract DeployRaffle is Script{
    function run() external returns(Raffle, HelperConfig) {  
        HelperConfig helperConfig = new HelperConfig(); // memanggil contract HelperConfig
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployKey ) = helperConfig.ActiveNetworkConfig();  // mengambil variable dari ActiveNetworkConfig
        
        if(subscriptionId == 0){
            // kita harus membuat subscriptionID!
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator, deployKey);

            // Fund it!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployKey);


        }

        // melaunch raffle ( membuat raffle baru)
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

        // menambahkan consumer baru
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, deployKey);
        return (raffle, helperConfig);

    }   
}
