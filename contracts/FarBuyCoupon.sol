// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract FarBuyCoupon is VRFV2WrapperConsumerBase, AutomationCompatibleInterface {

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
      uint8 minNumOfTickets;
      uint8 numOfWinners;
      bool isDrawn;
    }

    event WinnersChosen(uint32 indexed couponID);

    mapping(uint32 => Coupon) public coupons;  // couponID => Coupon
    mapping(uint32 => mapping(uint32 => Ticket)) public tickets;  // couponID => ticketNum => Ticket
    mapping(uint32 => uint32[]) public ticketNums;  // couponID => array of ticketNum

    uint public ticketPrice;

    bool public isPickingWinners;
    uint32 public processingCouponID;

    // VRF variables
    uint32 public callbackGasLimit;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint public lastRequestId;

    constructor(
        uint _ticketPrice,
        address _linkAddress,
        address _wrapperAddress,
        uint32 _callbackGasLimit
    )
    VRFV2WrapperConsumerBase(
        _linkAddress,              // LINK token address
        _wrapperAddress            // VRF wrapper
    )
    {
        owner = msg.sender;

        ticketPrice = _ticketPrice;

        callbackGasLimit = _callbackGasLimit;
    }

    function checkUpkeep(
        bytes calldata checkData
    )
        external view override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (keccak256(checkData) == keccak256(hex'01')) {
          for(uint32 i = 0; i < coupons.length; i++) {
            upkeepNeeded = false;
            performData = checkData;
          }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if (keccak256(performData) == keccak256(hex'01')) {
            require(!isPickingWinners);

            chooseWinners();
        }
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

    function generateRandomNumbers(uint8 countRandomNums) internal virtual {
        uint requestId = requestRandomness(callbackGasLimit, REQUEST_CONFIRMATIONS, countRandomNums);
        lastRequestId = requestId;
    }

    function fulfillRandomWords(uint requestId, uint256[] memory randomness) internal override {
        require(requestId == lastRequestId, "Invalid request");
        require(randomness[0] != 0, "Problem in getting randomness");

        for(uint8 i; i < coupons[processingCouponID].numOfWinners; i++) {
          uint idx = randomness[i] % ticketNums[processingCouponID].length;
          uint32 ticketNum = ticketNums[processingCouponID][idx];

          tickets[processingCouponID][ticketNum].isWinner = true;
        }

        // set isDrawn flag to avoid drawing again for the this coupon
        coupons[processingCouponID].isDrawn = true;

        isPickingWinners = false;

        // Emit an event with the winners
        emit WinnersChosen(processingCouponID);
    }

    function chooseWinners(uint32 couponID) public {

        require(!coupons[couponID].isDrawn, "Already been drawn");
        require(ticketNums[couponID].length >= coupons[couponID].minNumOfTickets, "Not enough tickets for the drawing");

        isPickingWinners = true;

        processingCouponID = couponID;
        generateRandomNumbers(coupons[couponID].numOfWinners);
    }

    function setCallbackGasLimit(uint32 _val) external onlyOwner {
        callbackGasLimit = _val;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}