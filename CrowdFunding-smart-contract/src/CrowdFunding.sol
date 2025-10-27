// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/* 
@title CrowdFunding
@Divine
@notice A simple crowdfunding contract:
•	Should  allow multiple contributors
•	Should have a fundraising goal (target amount)
•	funds Should only be released to the project owner if the goal is met
•	What happens if the goal is not reached (refunds)?
*/
contract CrowdFunding {
    using PriceConverter for uint256;
    /////////////////////////Errors/////////////////////////

    error CrowdFunding__NotOwner();
    error CrowdFunding__InsufficientContribution();
    error CrowdFunding__GoalNotReached();
    error CrowdFunding__TransferFailed();
    error CrowdFunding__NoContributions();
    error CrowdFunding__GoalAlreadyReached();
    error CrowdFunding__CrowdFundingClosed();
    /////////////////////////End of Errors/////////////////////////

    enum CrowdFundingState {
        OPEN,
        CLOSED
    }

    address private immutable i_owner;
    uint256 public constant MINIMUM_CONTRIBUTION = 5 * 10e18; // $5
    uint256 public constant TARGET_AMOUNT = 1 ether;
    uint256 public totalContributed;
    CrowdFundingState private s_crowdFundingState = CrowdFundingState.OPEN;
    AggregatorV3Interface private s_priceFeed;
    uint256 public immutable i_deadline;

    ////////////////////Events///////////////////////

    /*@Event*/
    event ContributionReceived(address indexed contributor, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    ////////////////////Modifiers///////////////////////
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert CrowdFunding__NotOwner();
        }
        _;
    }

    ////////////////////End of Modifiers///////////////////////

    struct Contributor {
        uint256 amount;
    }
    mapping(address => Contributor) public contributorData;

    address[] public contributors;

    constructor(address pricefeed, uint256 _deadline) {
        i_owner = msg.sender;
        s_crowdFundingState = CrowdFundingState.OPEN; // Initialize state to OPEN
        s_priceFeed = AggregatorV3Interface(pricefeed);
        i_deadline = block.timestamp + (_deadline + 1 days);
    }

    function contribute() public payable {
        //set a minimum contribution amount in usd equivalent (0.01 ether)
        //use chainlink price feed for this
        //using CEI pattern

        //Check if the contribution is >= minimum
        if (block.timestamp > i_deadline) {
            s_crowdFundingState = CrowdFundingState.CLOSED;
        }

        if (s_crowdFundingState != CrowdFundingState.OPEN) {
            revert CrowdFunding__CrowdFundingClosed();
        }

        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_CONTRIBUTION) {
            revert CrowdFunding__InsufficientContribution();
        }

        //Update the contributor's data
        if (contributorData[msg.sender].amount == 0) {
            contributorData[msg.sender] = Contributor(msg.value);
            contributors.push(msg.sender);
            totalContributed += msg.value;
            emit ContributionReceived(msg.sender, msg.value);
        } else {
            contributorData[msg.sender].amount += msg.value;
            emit ContributionReceived(msg.sender, msg.value);
            totalContributed += msg.value;
        }
    }

    ////////////////////////////Refund function if goal not reached///////////////////////

    function refund() public payable {
        //check if the goal is reached
        //if the goal is reached, revert with an error
        if (block.timestamp > i_deadline) {
            s_crowdFundingState = CrowdFundingState.CLOSED;
        }
        if (totalContributed >= TARGET_AMOUNT) {
            revert CrowdFunding__GoalAlreadyReached();
        }
        //check if the contributor has contributed
        //if not, revert with an error
        if (contributorData[msg.sender].amount == 0) {
            revert CrowdFunding__NoContributions();
        }

        //get the amount contributed by the contributor
        uint256 amountContributed = contributorData[msg.sender].amount;

        //set the contributor's amount to 0 before transferring to prevent re-entrancy attacks
        contributorData[msg.sender].amount = 0;

        //transfer the amount contributed back to the contributor
        (bool success, ) = payable(msg.sender).call{value: amountContributed}(
            ""
        );
        if (!success) {
            revert CrowdFunding__TransferFailed();
        }

        //update the total contributed amount
        totalContributed -= amountContributed;
    }

    //////////////////////////// End of Refund function if goal not reached///////////////////////

    function withdraw() public payable onlyOwner {
        //only owner can withdraw
        //transfer the funds to the owner

        if (block.timestamp > i_deadline) {
            s_crowdFundingState = CrowdFundingState.CLOSED;
        }

        if (address(this).balance < TARGET_AMOUNT) {
            revert CrowdFunding__GoalNotReached();
        }
        //create an array that maps through all contributors and sets their amount to 0
        for (
            uint256 contributorIndex = 0;
            contributorIndex < contributors.length;
            contributorIndex++
        ) {
            address contributor = contributors[contributorIndex];
            contributorData[contributor].amount = 0;
        }
        //reset the contributors array
        contributors = new address[](0);
        totalContributed = 0;

        (bool success, ) = payable(i_owner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert CrowdFunding__TransferFailed();
        }
        emit FundsWithdrawn(i_owner, address(this).balance);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAllContributors() public view returns (address[] memory) {
        return contributors;
    }

    function getAmountContributed(
        address contributor
    ) public view returns (uint256) {
        return contributorData[contributor].amount;
    }

    function getCrowdFundingState() public view returns (CrowdFundingState) {
        return s_crowdFundingState;
    }

    function getDeadline() public view returns (uint256) {
        return i_deadline;
    }
}
