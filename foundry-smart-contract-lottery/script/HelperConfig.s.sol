//SPDX-license-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script{
    struct NetworkConfig{
        // mengambil dari contructor di Raffle.sol
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }
    NetworkConfig public ActiveNetworkConfig;

    constructor(){      // contructor untuk memilih sepoliaEth atau Anvil 
        if(block.chainid == 11155111){   // chainid untuk sepoliaEth
            ActiveNetworkConfig = getSepoliaEthConfig();
        }
        else{
            ActiveNetworkConfig = getorCreateAnvilEthConfig();
        }
    }

    // digunakan untuk deploy pada network SepoliaEth
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c , // 150 gwei Key Hash SepoliaEth 
            subscriptionId: 0,  // nanti akan diupdate dengan sub ID yang kita punya
            callbackGasLimit: 500000  // 500,000 gas
        });
    }

    // digunakan jika memilih network Anvil (local network)
    function getorCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        if(ActiveNetworkConfig.vrfCoordinator != address(0)){
            return ActiveNetworkConfig;
        }

        // sesuai dengan contructor di VRFCoordinatorV2Mock()
        uint96 baseFee = 0.25 ether;    // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 9gwei 

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink); 
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c , // 150 gwei Key Hash SepoliaEth 
            subscriptionId: 0,  // nanti akan diupdate dengan sub ID yang kita punya
            callbackGasLimit: 500000  // 500,000 gas
        });
    }
}