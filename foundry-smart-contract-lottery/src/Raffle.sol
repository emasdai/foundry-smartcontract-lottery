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

    // constuctor dieksekusi pada saat pembuatan kontrak
    constructor(uint256 entranceFee){
        i_entranceFee = entranceFee;
    }

    // menggunakan external untuk gas fee lebih efisien
    function enterRaffle() external payable{
        
        if(msg.value < i_entranceFee){  //  jika msg.value(Eth) kurang dari i_entranceFee, maka akan revert ke NotEnoughEthSend
            revert Raffle__NotEnoughEthSend(); 
        }
    }

    function pickWinner() public{}

    //getter function
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}