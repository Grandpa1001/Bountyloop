// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bountyloop is Ownable {
    using Counters for Counters.Counter;

    event BountyStarted(bytes32 bountyId, address account);
    event WithdrawFunds(bytes32 bountyId, address charity, uint256 amount);
    event BountyDonated(bytes32 bountyId, address donor, uint256 amount);

    Counters.Counter public _campaignCount;

    struct Campaign {
        string title;
        string imgUrl;
        string description;
        uint256 fundsRaised;
        bool isLive;
        address account;
        uint256 balance;
    }

    mapping(bytes32 => Campaign) public _campaigns;
    mapping(address => mapping(bytes32 => uint256)) public userCampaignDonations;

    constructor() {}

    function startCampaign(
        address account,
        string calldata title,
        string calldata description,
        string calldata imgUrl,
        uint256 deadline
    ) public onlyOwner {
        bytes32 bountyId = generateBountyId(account, title, description);

        Campaign storage campaign = _campaigns[bountyId];
        require(!campaign.isLive, "Bounty campaign exists");
        require(block.timestamp < deadline, "Bounty campaign ended");

        campaign.title = title;
        campaign.description = description;
        campaign.account = account;
        campaign.imgUrl = imgUrl;
        campaign.isLive = true;

        _campaignCount.increment();

        emit BountyStarted(bountyId, account);
    }

    function generateBountyId(address account, string calldata title, string calldata description)
        public
        pure
        returns (bytes32)
    {
        bytes32 bountyId = keccak256(abi.encodePacked(account, title, description));
        return bountyId;
    }

    function stopCampaign(bytes32 bountyId) public onlyOwner {
        Campaign storage campaign = _campaigns[bountyId];
        require(campaign.isLive, "Campaign is not live");

        campaign.isLive = !campaign.isLive;
    }

    function donateToCampaign(bytes32 bountyId) public payable {
        Campaign storage campaign = _campaigns[bountyId];

        require(msg.value > 0, "Wrong ETH value");

        uint256 amountToDonate = msg.value;
        campaign.fundsRaised += amountToDonate;
        campaign.balance += amountToDonate;

        userCampaignDonations[msg.sender][bountyId] = amountToDonate;

        emit BountyDonated(bountyId, msg.sender, amountToDonate);
    }

    function getCampaign(bytes32 bountyId) public view returns (Campaign memory) {
        return _campaigns[bountyId];
    }

    function withdrawCampaignFunds(bytes32 bountyId) public {
        Campaign storage campaign = _campaigns[bountyId];
        require(campaign.balance > 0, "No funds to withdraw");
                payable(campaign.account).transfer(campaign.balance);
                emit WithdrawFunds(bountyId, campaign.account, campaign.balance);
    }   
}