// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffel.sol";

contract RaffleTest is Test{
    Raffle raffle;
    address public PLAYER= makeAddr("PLayer");
    uint256 public STARTING_PLAYER_BALANCE=10 ether;
    function setUp() external{
     raffle= new Raffle();
    }

    function testRaffleStateIsOpen() public {
        assert(raffle.getRaffleState()==raffle.RaffleState.OPEN);
    }
} 