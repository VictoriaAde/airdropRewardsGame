// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts@0.8.0/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts@0.8.0/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts@0.8.0/src/v0.8/shared/access/ConfirmedOwner.sol";

contract AirdropRewardGame is VRFConsumerBaseV2, ConfirmedOwner{
    IERC20 public prizeToken;
    uint64 s_subscriptionId;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event AirdropDistributed(address winner, uint256 amount);
    event WinnersSelected(address[] winners, uint256 amounts);

    VRFCoordinatorV2Interface COORDINATOR;

    uint32 callbackGasLimit = 400000;
    uint16 requestConfirmations;
    uint32 numWords;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public requestStatusMap;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    struct Participant {
        uint256 id;
        address participantAddress;
        uint256 entries;
        bool isRegistered;
    }

    uint256 private nextParticipantId = 1;

    uint256 public prizePool;

    struct ContentSubmission {
        address participant;
        string content;
        uint256 timestamp;
    }

    address[] public participantsAddr;
    address[] public  winners;
    mapping(address => Participant) public participantsMap;
    mapping (address => ContentSubmission) public contentSubmissionMap;
    mapping(address => uint256) public participantIdsByAddress;

    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    constructor(address _prizeToken, uint64 _subscriptionId)
        VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        prizeToken = IERC20(_prizeToken);
        s_subscriptionId = _subscriptionId;
    }

    function registerParticipant() external {
        require(!participantsMap[msg.sender].isRegistered, "Already registered");

        participantsMap[msg.sender] = Participant(nextParticipantId, msg.sender, 0, true);
        participantsAddr.push(msg.sender);
        participantIdsByAddress[msg.sender] = nextParticipantId;

        nextParticipantId++; 
    }

    function participateInActivity(string memory content) external {
        require(participantsMap[msg.sender].isRegistered, "Not registered");

        participantsMap[msg.sender].entries = participantsMap[msg.sender].entries + 1;
        contentSubmissionMap[msg.sender] = ContentSubmission(msg.sender, content, block.timestamp);
    }

    function setRandomNumOfWinners(uint32 _numWords) external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        numWords = _numWords;
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            _numWords
        );

        requestStatusMap[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, _numWords);
        return requestId;
    }

    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(requestStatusMap[_requestId].exists, "request not found");
        requestStatusMap[_requestId].fulfilled = true;
        requestStatusMap[_requestId].randomWords = _randomWords;
        selectWinners(_requestId);
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function selectWinners(uint256 requestId) internal {
        RequestStatus storage request = requestStatusMap[requestId];

        require(request.fulfilled, "Request not yet fulfilled");

        for (uint256 i = 0; i < numWords; i++) {
            uint256 index = (request.randomWords[i] + i) % participantsAddr.length;

            winners.push(participantsAddr[index]);

            emit WinnersSelected(winners, numWords);
        }
    }

    function calculatePrize(address _winner, uint256 _prizePool) internal returns (uint256) {
        require(winners.length < participantsAddr.length, "Number of winners exceeds total participants");
        require(prizeToken.balanceOf(msg.sender) >= _prizePool, "Prize greater than available token balance");

        prizeToken.transferFrom(msg.sender, address(this), _prizePool);
        uint256 prizeAmount = 10 * participantsMap[_winner].entries;
        
        return prizeAmount;
    }

    function distributePrizes() external onlyOwner {
         uint winnersEntries;

        for (uint256 i = 0; i < winners.length; i++) {
            winnersEntries = winnersEntries + participantsMap[winners[i]].entries;
        }

        prizePool = winnersEntries * 10;  

        for (uint i = 0; i < winners.length; i++) {
            address winner = winners[i]; // Use participant ID directly
            uint256 prizeAmount = calculatePrize(winner, prizePool);
            prizeToken.transfer(winner, prizeAmount); // Transfer the prize

            emit AirdropDistributed(winner, prizeAmount); // Emit event
        }
    }

}