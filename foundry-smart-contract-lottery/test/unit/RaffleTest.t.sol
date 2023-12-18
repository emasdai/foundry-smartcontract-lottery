// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol"; 
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";


contract RaffleTest is Test{

    /** Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;  // menyimpan variable Raffle pada raffle
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether; // 10 link

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle(); // memanggil kontrak DeployRaffle
        (raffle, helperConfig) = deployer.run();    // memanggil function run() dari DeployRaffle
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,
            
        ) = helperConfig.ActiveNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE); // menambahkan balance saat testing

        
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN); // mendapatkan enum dari RaffleState berupa OPEN
    }


    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSend.selector);    // akan revert error jika Eth yang dikirim kurang
        // Assert
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        //Assert
        assert(playerRecorded == PLAYER);
    }

    function testEmitEventOnEntrance() public { // testing event on foundry
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    function testCanEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval +1 ); // set block.time 
        vm.roll(block.timestamp + 1); // set block.number
        raffle.performUpKeep(""); // memanggil function PerformUpKeep pada Raffle.sol

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }   

    //// CheckUpKeep
    function testCheckUpKeepReturnsFalseIfitHasNoBalance()public{
        // semua dibuat positif untuk mengecek
        // Arrange
        vm.warp(block.timestamp + interval + 1);    // set block.time 
        vm.roll(block.number + 1);  // set block.number

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //assert
        assert(!upkeepNeeded); // assert tidak fales = true
    }

    function testCheckUpKeepReturnsFalseIfitRaffleNotOpen() public{
        // Arrrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");   // dalam CALCULATING_STATE
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(upkeepNeeded == false);
    }

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public{
        // arrage
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //act
        raffle.performUpKeep("");
    }

    function testPerformUpKeepRevertIfCheckUpKeepIsFalse() public {
        // arrange
        uint256 currentBalance = 0;
        uint256 numPlayer = 0;
        uint256 raffleState = 0;    // OPEN

        //ACT and Assert
        vm.expectRevert(        // memanggil varibel dari error di raffle.sol
            abi.encodeWithSelector(
                Raffle.Raffle__upkeepNotNeeded.selector, 
                currentBalance, 
                numPlayer, 
                raffleState
            )
        );   
        raffle.performUpKeep("");
    }

    // agar memudahkan coding, tidak perlu menulis prank, warp, roll dll.
    modifier raffleEnteredAndTimePassed(){
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
    // what if I need to test using the output of an event?
    // menambahkan modifier raffleEnteredAndTimePassed()
    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnteredAndTimePassed{
        // Act
        vm.recordLogs();    // merekam emitted event , agar bisa diakses gunakan getRecordedLogs
        raffle.performUpKeep("");   // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs(); // mendapatkan semua value dari events
        bytes32 requestId = entries[1].topics[1]; // mengambil index 1 pada requestId

        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0); // memastikan requestId sudah digenerate
        assert(uint256(rState) == 1 );  // STATE = CALCULATING
    }

    modifier skipFork(){
        if(block.chainid != 31337){ // jika 
            return;
        }
        _;
    }

    /// fulfillRandomWords
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestId) public raffleEnteredAndTimePassed skipFork{
        //arrange , mencoba fullfill mock untuk mendapatkan random number
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));    // mengambil function dari VRFCoordinatorV2Mock
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnteredAndTimePassed skipFork{
        // Arrange
        uint256 additionalEntrance = 5;    // untuk tambahan orang yang enter pada raffle
        uint256 startingIndex = 1;          // akan memulai pada index 1 (ke-2)

        for(uint256 i = startingIndex; i< startingIndex + additionalEntrance; i++){    // i dari 1 sampai 5, akan ditambah 1 secara terus sampai 5
            address player = address(uint160(i)); // address semua secara berulang address1,address2,address3
            hoax(player, STARTING_USER_BALANCE);   //set up prank dengan ether
            raffle.enterRaffle{value: entranceFee}();

        }

        uint256 prize = entranceFee * (additionalEntrance + 1); // entranceFee x 6 = uang semua orang / Total Prize


        // Act
        vm.recordLogs();    // merekam emitted event , agar bisa diakses gunakan getRecordedLogs
        raffle.performUpKeep("");   // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs(); // mendapatkan semua value dari events
        bytes32 requestId = entries[1].topics[1]; // mengambil index 1 pada requestId

        uint256 previousTimeStamp = raffle.getLastTimestamp();
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256 (requestId), address(raffle));    // mengambil function dari VRFCoordinatorV2Mock

        // assert
        assert(uint256(raffle.getRaffleState()) == 0);  // OPEN
        assert(raffle.getRecentWinner() != address(0)); // recent winner bukanlah yang address pertama
        assert(raffle.getLengthOfPlayer() == 0);    // direset setelah selesai
        assert(previousTimeStamp < raffle.getLastTimestamp());
        assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);  // balance pemenang == total prize - biasa masuk(entranceFee)
    }
}