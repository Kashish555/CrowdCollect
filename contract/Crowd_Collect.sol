// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Crowdfunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint goalAmount;
        uint currentAmount;
        bool completed;
        bool deleted; // Mark if the campaign is deleted
    }

    Campaign[] public campaigns;

    event CampaignCreated(uint campaignId, address owner, string title, uint goalAmount);
    event Funded(uint campaignId, address funder, uint amount, uint currentAmount);
    event FundsWithdrawn(uint campaignId, address owner, uint amount, uint remainingAmount);
    event CampaignDeleted(uint campaignId, address owner);

    function createCampaign(string memory title, string memory description, uint goalAmount) public {
        require(goalAmount > 0, "Goal amount must be greater than zero");
        
        Campaign memory newCampaign = Campaign({
            owner: msg.sender,
            title: title,
            description: description,
            goalAmount: goalAmount,
            currentAmount: 0,
            completed: false,
            deleted: false
        });

        campaigns.push(newCampaign);
        emit CampaignCreated(campaigns.length - 1, msg.sender, title, goalAmount);
    }

    function fundCampaign(uint campaignId) public payable {
        require(campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[campaignId];
        require(!campaign.completed, "Campaign already completed");
        require(!campaign.deleted, "Campaign has been deleted");
        require(msg.value > 0, "Funding amount must be greater than 0");

        campaign.currentAmount += msg.value;

        if (campaign.currentAmount >= campaign.goalAmount) {
            campaign.completed = true;
        }

        emit Funded(campaignId, msg.sender, msg.value, campaign.currentAmount);
    }

    function withdrawFunds(uint campaignId) public {
        require(campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[campaignId];
        require(msg.sender == campaign.owner, "Only the campaign owner can withdraw funds");
        require(campaign.currentAmount > 0, "No funds available to withdraw");
        require(!campaign.deleted, "Campaign has been deleted");

        uint amountToWithdraw = campaign.currentAmount;
        campaign.currentAmount = 0;

        (bool success, ) = campaign.owner.call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(campaignId, campaign.owner, amountToWithdraw, campaign.currentAmount);
    }

  function deleteCampaign(uint campaignId) public {
    require(campaignId < campaigns.length, "Campaign does not exist");

    delete campaigns[campaignId]; // Delete the campaign
}


    function getCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }
}
