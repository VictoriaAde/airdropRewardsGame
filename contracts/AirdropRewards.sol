// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interface/IERC20.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract AirdropRewardGame is VRFConsumerBaseV2, ConfirmedOwner{
    IERC20 public prizeToken;
    uint64 s_subscriptionId;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event AirdropDistributed(address winner, uint256 amount);

    VRFCoordinatorV2Interface COORDINATOR;

    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    struct Participant {
        uint256 id;
        address participantAddress;
        uint256 entries;
        bool isRegistered;
    }

    uint256 private nextParticipantId = 1;

    struct ContentSubmission {
        address participant;
        string content;
        uint256 timestamp;
    }

    Participant[] public participants;
    mapping(address => Participant) public participantsMap;
    mapping (address => ContentSubmission) public contentSubmissionMap;
    mapping(address => uint256) public participantIdsByAddress;

    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    constructor(address _vrfCoordinator, address _prizeToken, uint64 _subscriptionId)
        VRFConsumerBaseV2(_vrfCoordinator)
        ConfirmedOwner(msg.sender)
    {
        prizeToken = IERC20(_prizeToken);
        s_subscriptionId = _subscriptionId;
    }


    function registerParticipant() external {
        require(!participantsMap[msg.sender].isRegistered, "Already registered");

        participants.push(Participant(nextParticipantId, msg.sender, 0, true));
        participantsMap[msg.sender] = Participant(nextParticipantId, msg.sender, 0, true);
        participantIdsByAddress[msg.sender] = nextParticipantId; // Add this line

        nextParticipantId++; // Increment the ID for the next participant
    }


    function participateInActivity(string memory content) external {
        require(participantsMap[msg.sender].isRegistered, "Not registered");

        participantsMap[msg.sender].entries = participantsMap[msg.sender].entries + 1;

        contentSubmissionMap[msg.sender] = ContentSubmission(msg.sender, content, block.timestamp);
    }




    function distributePrizes() external onlyOwner {
        uint256[] memory winners = selectWinners(lastRequestId);

        for (uint i = 0; i < winners.length; i++) {
            uint256 amount = calculatePrize(winners[i]); // Use participant ID directly
            require(amount > 0, "Prize amount must be greater than zero"); // Ensure non-zero prize amount

            prizeToken.transfer(participants[winners[i]].participantAddress, amount); // Transfer the prize
            emit AirdropDistributed(participants[winners[i]].participantAddress, amount); // Emit event
        }
    }



    function selectWinners(uint256 requestId) internal view returns (uint256[] memory) {
        RequestStatus storage request = s_requests[requestId];
        require(request.fulfilled, "Request not yet fulfilled");

        // Assuming you want to select a fixed number of winners, e.g., 3
        uint256 numWinners = 3;
        uint256[] memory winners = new uint256[](numWinners);

        // Create a temporary array to store the indices of participants based on their entries
        uint256[] memory entriesIndices = new uint256[](participants.length);
        for (uint i = 0; i < participants.length; i++) {
            entriesIndices[i] = i;
        }

        // Sort the entriesIndices array based on the participants' entries in descending order
        for (uint i = 0; i < participants.length - 1; i++) {
            for (uint j = i + 1; j < participants.length; j++) {
                if (participants[entriesIndices[i]].entries < participants[entriesIndices[j]].entries) {
                    uint256 temp = entriesIndices[i];
                    entriesIndices[i] = entriesIndices[j];
                    entriesIndices[j] = temp;
                }
            }
        }

        // Select the top numWinners participants as winners
        for (uint i = 0; i < numWinners; i++) {
            winners[i] = entriesIndices[participants.length - 1 - i];
        }

        return winners;
    }



    function calculatePrize(uint256 participantId) internal view returns (uint256) {
        // Assuming each entry is worth 1 token
        uint256 prizeAmount = participants[participantId].entries;
        return prizeAmount;
    }





    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords){
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
