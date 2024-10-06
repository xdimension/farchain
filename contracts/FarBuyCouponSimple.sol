// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract FarBuyCouponSimple {

    address owner;

    struct Ticket {
        uint32 couponID;
        uint32 ticketNum;
        uint timeOfEntry;
        address buyerAddr;
        bool isWinner;
    }

    struct Coupon {
      uint32 couponID;
      uint8 minEntries;
      uint timeEntriesAchieved;
    }

    mapping(uint32 => Coupon) public coupons;  // couponID => Coupon
    mapping(uint32 => mapping(uint32 => Ticket)) public tickets;  // couponID => ticketNum => Ticket
    mapping(uint32 => uint32[]) public ticketNums;  // couponID => array of ticketNum

    uint public ticketPrice;

    event entriesAchieved(uint32 couponId);

    constructor(
        uint _ticketPrice
    )
    {
        owner = msg.sender;

        ticketPrice = _ticketPrice;
    }

    function createTicket(uint32 _couponID) public {
        uint32 ticketNum = uint32(uint256(keccak256(abi.encodePacked(owner, block.timestamp))));

        tickets[_couponID][ticketNum] = Ticket(
                                            _couponID,
                                            ticketNum,
                                            block.timestamp,
                                            msg.sender,
                                            false
                                          );

        ticketNums[_couponID].push(ticketNum);

        if (coupons[_couponID].minEntries == ticketNums[_couponID].length) {
          coupons[_couponID].timeEntriesAchieved = block.timestamp;
          emit entriesAchieved(_couponID);
        }
    }

    function getTicket(uint32 _couponID, uint32 _ticketNum) public view returns (Ticket memory) {
        return tickets[_couponID][_ticketNum];
    }

    function getTicketsByCouponID(uint32 _couponID) public view returns (Ticket[] memory) {
        uint32 countTickets = uint32(ticketNums[_couponID].length);
        Ticket[] memory ticketList = new Ticket[](countTickets);

        for (uint32 i = 0; i < countTickets; i++) {
            uint32 ticketNum = ticketNums[_couponID][i];
            ticketList[i] = tickets[_couponID][ticketNum];
        }

        return ticketList;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}