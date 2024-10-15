// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {VRFConsumerBaseV2Plus} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Aditya
 * @notice This contract is for practise of foundry with integration of chainlink
 * @dev  Uses chainlink VRF
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__NotEnoughEthToEnter();
    error Raffle__TransferFailed();
    error Raffle__Notopen();
    // error Raffle__NotEnoughTimePassed();


    /**Type declarations */
    enum RaffleState{
        OPEN,
        CALCULATING
    }
  
     /**State Variables */
    uint256 private immutable i_entranceFee;
    //@dev The duration oflottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_LastTimeStamp;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_subscriptionId;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1;
    address private s_recentwinner;
    RaffleState private s_rafflestate;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_LastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_rafflestate=RaffleState.OPEN;
    }

    function EnterRaffle() external payable {
        //    require(msg.value>=i_entranceFee,"Not enough eth sent");
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnter();
        }
        if (s_rafflestate!=RaffleState.OPEN){
            revert Raffle__Notopen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is a function that chainlink node will see that lottery is ready to be picked
     */

    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */){
   bool Timehaspassed = ((block.timestamp - s_LastTimeStamp) >=i_interval) ;
   bool isOpen = s_rafflestate== RaffleState.OPEN;
   bool hasBalance= address(this).balance>0;
   bool hasplayers= s_players.length>0;
   upkeepNeeded= Timehaspassed&&isOpen&&hasBalance&&hasplayers;
   return(upkeepNeeded,"");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert();
        }
        if ((block.timestamp - s_LastTimeStamp) < i_interval) {
            revert  Raffle__TransferFailed();
        }
        s_rafflestate=RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexofwinner= randomWords[0]%s_players.length;
        address payable recentwinner= s_players[indexofwinner];
        s_recentwinner= recentwinner;
        s_rafflestate=RaffleState.OPEN;
        s_players= new address payable[](0);
        s_LastTimeStamp=block.timestamp;
        (bool success,)= recentwinner.call{value: address(this).balance}("");
        if(!success){
            revert();
        }
        emit WinnerPicked(s_recentwinner);
    }
    /**
     * Getter functions
     */

    function getEntrancefee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_rafflestate;
    }
}
