// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "@openzeppelin/contracts/utils/Counters.sol";

contract Charity {
    using Counters for Counters.Counter;

    event CampaignStarted(bytes32 campaignId, address initiator);
    event WithdrawFunds(bytes32 campaignId, address initiator, uint256 amount);
    event FundsDonated(bytes32 campaignId, address donor, uint256 amount);

    Counters.Counter public _campaignCount;

    struct Campaign {
        string title;
        string imgUrl;
        string description;
        uint256 fundsRaised;
        bool isLive;
        address initiator;
        uint256 deadline;
        uint256 balance;
    }

    mapping(bytes32=>Campaign) public _campaigns;
    mapping(address=>mapping(bytes32=>uint256)) public userCampaignDonations;

    constructor(){

    }

    function generateCampaignId(address initiator, string calldata title, string calldata description) public pure returns(bytes32) {
       bytes32 campaignId = keccak256(abi.encodePacked(title, description, initiator));
       return campaignId;
    }

    function startCampaign( string calldata title, string calldata description, string calldata imgUrl, uint256 deadline ) public {
        // generate a campaignID 
        // using the title, description and the address of the initiator
        bytes32 campaignId = generateCampaignId(msg.sender, title, description);

        // get a reference to the campaign with the generated Id
        Campaign storage campaign = _campaigns[campaignId];
        // require that the campaign is not live yet.
        require(!campaign.isLive, "Campaign exists");
        // require the current time to be less than the campaign deadline
        require(block.timestamp < deadline, "Campaign ended");

        campaign.title = title;
        campaign.description = description;
        campaign.initiator = msg.sender;
        campaign.imgUrl = imgUrl;
        campaign.deadline = deadline;
        campaign.isLive = true;

        // increment the total number of charity campaigns created
        _campaignCount.increment();

        // emit an event to the blockchain
        emit CampaignStarted(campaignId, msg.sender);
    }

    function endCampaign() public {

    }

    // allows users to donate to a charity campaign of their choice
    function donateToCampaign(bytes32 campaignId) public payable {
        // get campaign details with the given campaign
        Campaign storage campaign = _campaigns[campaignId];

        // end the campaign if the deadline is exceeded
        if(block.timestamp > campaign.deadline){
            campaign.isLive = false;
        }
        // require the campaign has not ended
        require(block.timestamp < campaign.deadline, "Campaign has ended");

        uint256 amountToDonate = msg.value;
        require(amountToDonate > 0, "Wrong ETH value");

        // increase the campaign balance by the amount donated;
        campaign.fundsRaised += amountToDonate;
        campaign.balance += amountToDonate;

        // keep track of users donation history
        userCampaignDonations[msg.sender][campaignId] = amountToDonate;

        // emit FundsDonated event
        emit FundsDonated(campaignId, msg.sender, amountToDonate);
    }

    // returns the details of a campaign given the campaignId
    function getCampaign(bytes32 campaignId) public view returns(Campaign memory) {
        return _campaigns[campaignId];
    }

    function withdrawCampaignFunds(bytes32 campaignId) public {
        Campaign storage campaign = _campaigns[campaignId];

        // require the msg.sender is the creator of the campaign
        require(msg.sender == campaign.initiator, "Not campaign initiator");
        // require the campaign has ended
        require(!campaign.isLive, "campaign is still active");
        require(block.timestamp > campaign.deadline, "Campaign is still active");
        // require the campaign has funds to be withdrawn
        require(campaign.balance > 0, "No funds to withdraw");

        uint256 amountToWithdraw = campaign.balance;

        // zero the campaign balance
        campaign.balance = 0;

        // transfer the balance to the initiator address;
        payable(campaign.initiator).transfer(amountToWithdraw);

        // emit an event to the blockchain
        emit WithdrawFunds(campaignId, campaign.initiator, amountToWithdraw);
    }

}