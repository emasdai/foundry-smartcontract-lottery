// SPDX-license-Identifier: MIT

pragma solidity ^0.8.18;

/**
    *   @title  a sample raffle contract
    *   @author emasdai
    *   @notice this contract for creating sample raffle
    *   @dev    implement chainlin VRFv2 
 */
contract Raffle {

    uint256 private immutable i_entranceFee;  // i_ adalah immutable, untuk menghemat gas Fee

    // constuctor dieksekusi pada saat pembuatan kontrak
    constructor(uint256 entranceFee){
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable{}

    function pickWinner() public{}

    //getter function
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}