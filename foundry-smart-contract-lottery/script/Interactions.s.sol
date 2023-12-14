// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/Linktoken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns(uint64){
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig.ActiveNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint64){
        console.log("creating Subscription on ChainId: ", block.chainid);
        vm.startBroadcast();
        uint64 subId =  VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub id is:" , subId);
        return subId;
    }

    function run() external returns(uint64){
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubcriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , address link) = helperConfig.ActiveNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address link) public{
        console.log("Funding Subsription", subId);
        console.log("Using VrfCoordinator", vrfCoordinator);
        console.log("On ChainId", block.chainid);
        if(block.chainid == 31337){  // local chain
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId,FUND_AMOUNT);
            vm.stopBroadcast();

        }else{
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }

    }

    function run() external {
        fundSubcriptionUsingConfig();
    }
}

contract AddConsumer is Script{

    function addConsumer(address raffle, address vrfCoordinator, uint64 subId) public{
        console.log("Adding consumer Contract   : ", raffle);
        console.log("Using VRFCoordinator       : ", vrfCoordinator);
        console.log("On ChainId                 : ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();

    }

    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, ,) = helperConfig.ActiveNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}