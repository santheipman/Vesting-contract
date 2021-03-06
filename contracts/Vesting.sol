// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TestToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting {
    struct UserInfo {
        uint amount;
        uint tokenClaimed;
    }

    mapping(address => UserInfo) private userInfoList;

    IERC20 private token;
    uint256 private firstRelease; // "fistReleaseRatio = 20" means 20% of max amount of claimable tokens will be released first
    uint256 private startTime;
    uint256 private totalPeriod;
    uint256 private timePerPeriod;
    uint256 private cliff;
    uint256 private totalTokens;
    address private admin;

    event TokenClaimed(address _claimer, uint256 _claimedAmount);
    event UserAddedToWhitelist(address _user, uint256 _amount);
    event UserRemovedFromWhitelist(address _user);

    constructor(
        address _token,
        uint256 _firstRelease,
        uint256 _startTime,
        uint256 _totalPeriod,
        uint256 _timePerPeriod,
        uint256 _cliff,
        uint256 _totalTokens,
        address _admin
    ) {
        token = IERC20(_token);
        firstRelease = _firstRelease;
        startTime = _startTime;
        totalPeriod = _totalPeriod;
        timePerPeriod = _timePerPeriod;
        cliff = _cliff;
        totalTokens = _totalTokens;
        admin = _admin;
    }

    // -----------------------------------------------------
    // Helper functions
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function getUserAmount(address user) external onlyAdmin view returns (uint){
        return userInfoList[user].amount;
    }

    function getUserTokenClaimed(address user) external onlyAdmin view returns (uint){
        return userInfoList[user].tokenClaimed;
    }

    function currentClaimableAmount(uint256 currentTime, UserInfo memory user) public view returns (uint256) {
        // max amount
        uint256 actualClaimableAmount;
        
        if (currentTime < startTime) {
            actualClaimableAmount = 0; // before the first release, there's no token to be claimed
        } else {
            uint256 maxAmount;
            uint256 tmp = user.amount / 100 * firstRelease;
            if (currentTime < startTime + cliff) {
                maxAmount = tmp; // during cliff, max claimable amount equals to first release amount (20%)
            } else {
                if (currentTime - (startTime + cliff) >= timePerPeriod * totalPeriod) {
                    maxAmount = user.amount; // all periods have passed
                } else {
                    // after cliff and before last period
                    uint256 periods = (currentTime - (startTime + cliff)) / timePerPeriod;
                    maxAmount = tmp + (user.amount - tmp) * (periods + 1) / totalPeriod;
                }
            }
            actualClaimableAmount = maxAmount - user.tokenClaimed;
        }
        return actualClaimableAmount;
    }

    // ------------------------------------------------------
    // Main functions
    function addUserToWhitelist(address user, uint256 amount) external onlyAdmin {
        userInfoList[user].amount = amount;
        userInfoList[user].tokenClaimed = 0;

        emit UserAddedToWhitelist(user, amount);
    }

    function removeUserFromWhitelist(address user) external onlyAdmin {
        delete userInfoList[user];

        emit UserRemovedFromWhitelist(user);
    }

    function claimToken() public {
        address claimer = msg.sender;
        uint claimableAmount = currentClaimableAmount(block.timestamp, userInfoList[claimer]);

        token.transfer(claimer, claimableAmount);

        emit TokenClaimed(claimer, claimableAmount);

        userInfoList[claimer].tokenClaimed += claimableAmount;
    }

    // function vestingFund() external onlyAdmin returns(bytes memory){
    //     // (bool success, bytes memory data) = address(token).delegatecall(abi.encodeWithSignature("transfer(address,uint256)", address(this), totalTokens));
    //     // token.transfer
    // }

}