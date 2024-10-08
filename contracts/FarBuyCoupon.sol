// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FarBuyCoupon is VRFConsumerBaseV2Plus {
    // address owner;

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
        uint8 maxNumOfTickets;
        uint8 numOfWinners;
        bool isDrawn;
    }

    event WinnersChosen(uint32 indexed couponID);

    uint32[] public couponIDs;
    mapping(uint32 => Coupon) public coupons; // couponID => Coupon
    mapping(uint32 => mapping(uint32 => Ticket)) public tickets; // couponID => ticketNum => Ticket
    mapping(uint32 => uint32[]) public ticketNums; // couponID => array of ticketNum

    uint public ticketPrice;

    bool public isChoosingWinners;

    // VRF variables
    uint256 vrf_subscriptionId;
    bytes32 public vrf_keyHash;
    uint32 public vrf_callbackGasLimit = 1_000_000;
    bool public vrf_nativePayment = false;
    uint16 constant VRF_REQUEST_CONFIRMATIONS = 3;
    uint public vrf_lastRequestId;

    mapping(uint => uint32) randomizeRequests; // requestId => couponID

    constructor(
        uint _ticketPrice,
        uint256 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        // owner = msg.sender;

        ticketPrice = _ticketPrice;

        vrf_subscriptionId = _subscriptionId;
        vrf_keyHash = _keyHash;
    }

    function createCoupon(
        uint32 _couponID,
        uint8 _minNumOfTickets,
        uint8 _maxNumOfTickets,
        uint8 _numOfWinners
    ) public onlyOwner {
        require(
            _minNumOfTickets <= _maxNumOfTickets,
            "Min number of tickets must be less than or equal to max number of tickets"
        );
        require(
            _numOfWinners <= _maxNumOfTickets,
            "Number of winners must be less than or equal to max number of tickets"
        );

        coupons[_couponID] = Coupon(
            _couponID,
            _minNumOfTickets,
            _maxNumOfTickets,
            _numOfWinners,
            false
        );
    }

    function getCoupon(uint32 _couponID) public view returns (Coupon memory) {
        return coupons[_couponID];
    }

    function createTicket(uint32 _couponID) public payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(coupons[_couponID].couponID != 0, "Invalid Coupon ID");
        require(
            ticketNums[_couponID].length < coupons[_couponID].maxNumOfTickets,
            "Maximum ticket limit reached"
        );

        uint32 ticketNum = uint32(
            uint256(keccak256(abi.encodePacked(owner(), block.timestamp)))
        );

        tickets[_couponID][ticketNum] = Ticket(
            _couponID,
            ticketNum,
            block.timestamp,
            msg.sender,
            false
        );

        ticketNums[_couponID].push(ticketNum);
    }

    function getTicket(
        uint32 _couponID,
        uint32 _ticketNum
    ) public view returns (Ticket memory) {
        return tickets[_couponID][_ticketNum];
    }

    function getTicketsByCouponID(
        uint32 _couponID
    ) public view returns (Ticket[] memory) {
        uint32 countTickets = uint32(ticketNums[_couponID].length);
        Ticket[] memory ticketList = new Ticket[](countTickets);

        for (uint32 i = 0; i < countTickets; i++) {
            uint32 ticketNum = ticketNums[_couponID][i];
            ticketList[i] = tickets[_couponID][ticketNum];
        }

        return ticketList;
    }

    function generateRandomNumbers(uint32 couponID) internal virtual {

        uint requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: vrf_keyHash,
                subId: vrf_subscriptionId,
                requestConfirmations: VRF_REQUEST_CONFIRMATIONS,
                callbackGasLimit: vrf_callbackGasLimit,
                numWords: uint32(ticketNums[couponID].length),
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        vrf_lastRequestId = requestId;
        randomizeRequests[requestId] = couponID;
    }

    function fulfillRandomWords(
        uint requestId,
        uint256[] calldata randomness
    ) internal override {
        require(randomness[0] != 0, "Problem in getting randomness");

        uint32 couponID = randomizeRequests[requestId];
        uint8 countTickets = uint8(ticketNums[couponID].length);

        for (uint8 i = countTickets - 1; i > 0; i--) {
            uint256 j = randomness[countTickets - i - 1] % (i + 1);
            (ticketNums[couponID][i], ticketNums[couponID][j]) = (ticketNums[couponID][j], ticketNums[couponID][i]);
        }

        for(uint8 i = 0; i < coupons[couponID].numOfWinners; i++) {
            uint32 ticketNum = ticketNums[couponID][i];
            tickets[couponID][ticketNum].isWinner = true;
        }

        // set isDrawn flag to avoid drawing again for the this coupon
        coupons[couponID].isDrawn = true;
        isChoosingWinners = false;

        // Emit an event with the winners
        emit WinnersChosen(couponID);
    }

    function chooseWinners(uint32 couponID) public onlyOwner {
        require(coupons[couponID].couponID != 0, "Invalid Coupon ID");
        require(!isChoosingWinners, "In progress");
        require(!coupons[couponID].isDrawn, "Coupon already been drawn");
        require(
            ticketNums[couponID].length >= coupons[couponID].minNumOfTickets,
            "Not enough tickets for the drawing"
        );

        isChoosingWinners = true;

        generateRandomNumbers(couponID);
    }

    function setVRFCallbackGasLimit(uint32 _val) external onlyOwner {
        vrf_callbackGasLimit = _val;
    }

    function setVRFNativePayment(bool _val) external onlyOwner {
        vrf_nativePayment = _val;
    }

    // function owner() public view returns(address) {
    //   return owner;
    // }

    // modifier onlyOwner() {
    //   require(msg.sender == owner);
    //   _;
    // }
}
