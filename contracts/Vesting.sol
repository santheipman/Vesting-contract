// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TestToken.sol";

contract Vesting {
    struct UserInfo {
        uint amount;
        uint tokenClaimed;
    }

    mapping(address => UserInfo) private userInfoList;

    uint256 private firstRelease;
    uint256 private startTime;
    uint256 private totalPeriod;
    uint256 private timePerPeriod;
    uint256 private cliff;
    uint256 private totalTokens;
    address private admin;

    constructor(
        uint256 _firstRelease,
        uint256 _startTime,
        uint256 _totalPeriod,
        uint256 _timePerPeriod,
        uint256 _cliff,
        uint256 _totalTokens,
        address _admin
    ) {
        firstRelease = _firstRelease;
        startTime = _startTime;
        totalPeriod = _totalPeriod;
        timePerPeriod = _timePerPeriod;
        cliff = _cliff;
        totalTokens = _totalTokens;
        admin = _admin;
    }


    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function addUserToWhitelist(address user, uint256 amount) external onlyAdmin {
        userInfoList[user].amount = amount;
        userInfoList[user].tokenClaimed = 0;
    }

    function removeUserFromWhitelist(address user) external onlyAdmin {
        delete userInfoList[user];
    }

    function vestingFund() external onlyAdmin payable {
        require(msg.value == totalTokens, "Admin must send correct amount of token to the contract");
    }

}