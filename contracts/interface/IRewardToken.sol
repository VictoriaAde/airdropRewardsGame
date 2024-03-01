// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


interface IRewardToken {
    function registerParticipant() external;
    function participateInActivity(string memory content) external;
    function distributePrizes() external;
    function requestRandomWords() external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords);
}