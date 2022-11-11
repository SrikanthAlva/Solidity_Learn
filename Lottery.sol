//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Lottery {

    struct Lottery {
        string Name;
        address creator;
        uint startTime;
        uint endTime;
        uint tickerPrice;
    }

    address owner;

    Lottery public lotery;

    uint totalTicketsSold = 0;

    // Ticket to Address of Buyer Mapping
    mapping(uint => address) lotteryBuyer;

    constructor(string memory name, uint _startTime, uint _endTime) {
        owner = msg.sender;
        lotery = Lottery({Name: name, creator: msg.sender, startTime: block.timestamp + _startTime, endTime: block.timestamp + _endTime, tickerPrice: 1 ether});
    }

    function buyTickets(uint quantity ) payable external {
        // Check whether the user is paying required ethers to buy x amount of tickets
        // should permit ticket buying after startTIme and before endTime of the Lottery
        // Owner cannot buy tickets
        // Max tickets is 20
        // User should be able to buy tickets
        // Store the information about the tickets about.
    }

    function findWinner() external {
        // restrict access to this function only to Owner
        // should be executed only after the endTime of the Lottery
        // rand = random number generation code

        // winnerId = rand % totalTicketsSold;
    }

    function winnerWithdraw() external {
        // Only the winner can withdraw funds
        // Should allow the winner to withdraw only 80% of the funds collected
        // Winner can withdraw only once.
    }


    function ownerWithdraw() external {
        // Only the owner can withdraw funds
        // Should allow the owner to withdraw only 20% of the funds collected
        // Winner can withdraw only once.
    }

}
