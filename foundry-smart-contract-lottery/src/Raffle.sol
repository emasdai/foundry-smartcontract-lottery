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
contract Raffle {
    error Raffle__NotEnoughEthSend();   // digunakan jika eth yang di sent kurang, error digunakan untuk efisiensi gas fee, menggunakan awalan nama contract agar mudah diketahui saat error
    
    uint256 private immutable i_entranceFee;  // i_ adalah immutable, untuk menghemat gas Fee
    uint256 private immutable i_interval;   // durasi dari lottery dalam detik
    address payable[] private s_player;     // array yang digunakan untuk menyimpan address s_ adalah storage variable, payable dapat menerima eth didalam kontrak
    uint256 private s_LastTimeStamp;

    /** EVENT */
    event EnteredRaffle(address indexed player);

    // constuctor dieksekusi pada saat pembuatan kontrak
    constructor(uint256 entranceFee, uint256 interval){
        i_entranceFee = entranceFee;
        i_interval = interval;
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
        
    }

    //getter function
    function getEntranceFee() external view returns(uint256) {  // external agar semua orang bisa melihat i_entranceFee
        return i_entranceFee;
    }
}