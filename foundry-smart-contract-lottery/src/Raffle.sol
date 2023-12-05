// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-license-Identifier: MIT
pragma solidity ^0.8.18;

/**
    *   @title  a sample raffle contract
    *   @author emasdai
    *   @notice this contract for creating sample raffle
    *   @dev    implement chainlin VRFv2 
 */

import {VRFCoordinatorV2Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";

abstract contract Raffle is VRFConsumerBaseV2 {

    error Raffle__NotEnoughEthSend();   // digunakan jika eth yang di sent kurang, error digunakan untuk efisiensi gas fee, menggunakan awalan nama contract agar mudah diketahui saat error
    address payable[] private s_player;     // array yang digunakan untuk menyimpan address s_ adalah storage variable, payable dapat menerima eth didalam kontrak

    /** STATE VARIABLE */
    // Constants are variables that cannot be modified. UPPERCASE agar gas efisien
    uint16 private constant REQUEST_CONFIRMATION = 3; // banyaknya konfirmasi yang akan dikirim
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;  // i_ adalah immutable, untuk menghemat gas Fee
    uint256 private immutable i_interval;   // durasi dari lottery dalam detik
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // address vrf coordinator untuk random number, mengambik dari function yang ada di VRFCoordinatorV2Interface
    bytes23 private immutable i_gasLane;    // KeyHash yang akan digunakan dalam chainlink vrf
    uint64 private immutable i_subscriptionId;  // 
    uint32 private immutable i_callbackGasLimit;   // max gas yang akan digunakan untuk request
    uint256 private s_LastTimeStamp;

    /** EVENT */
    event EnteredRaffle(address indexed player);

    // constuctor dieksekusi pada saat pembuatan kontrak
    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes23 gasLine, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLine;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_LastTimeStamp = block.timestamp;
    }

    // menggunakan external untuk gas fee lebih efisien
    function enterRaffle() external payable{
        
        if(msg.value < i_entranceFee){  //  jika msg.value(Eth) kurang dari i_entranceFee, maka akan revert ke NotEnoughEthSend
            revert Raffle__NotEnoughEthSend(); 
        }
        s_player.push(payable(msg.sender)); // akan menambahkan address pada array (storage) s_player, payable karena bisa mengirim eth ke contract
        emit EnteredRaffle(msg.sender);
    }

    /**
    1. mendapatkan random number
    2. menggunakan random number kepada player
    3. otomatis memanggil player */
    function pickWinner() external{
        if((block.timestamp - s_LastTimeStamp) < i_interval){ // cek untuk melihat apakah waktu yang digunakan sudah cukup
            revert();
        }
        // 1. request RNG <- Chainlink VRF
        // Will revert if subscription is not set and funded.
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,              // keyhash
            i_subscriptionId,       // Subscription ID
            REQUEST_CONFIRMATION,   // request confirmation
            i_callbackGasLimit,     // max gas yang akan digunakan untuk request
            NUM_WORDS               // nomor dari random number yang diinginkan
        );
    }

    // 
    function fulfillRandomWord( uint256 requestId, uint256[] memory randomWords) internal  {
        
    }

    //getter function
    function getEntranceFee() external view returns(uint256) {  // external agar semua orang bisa melihat i_entranceFee
        return i_entranceFee;
    }
}