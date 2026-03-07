// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
// Inside Contract:
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

/**
 * @title Voting contract
 * @author Deevyne99
 * @notice This implements a simple voting smart contract
 * @dev This is an example of a simple voting contract. It allows users to create proposals and vote on them. The contract keeps track of the votes and the winning proposal.
 */
contract Ballot {
    error Ballot__NotChairperson();
    error Ballot__AlreadyVoted();
    error Ballot__NotRegistered();
    error Ballot__InvalidProposal();
    error Ballot__VoterAlreadyRegistered();
    error Ballot__InvalidVoter();
    error Ballot__VotingAlreadyEnded();
    error Ballot__VotingNotEnded();
    // Type declarations

    //Voter record to keep track of the voter's information and voting status
    struct voterRecord {
        bool hasVoted; // to check if the voter has already voted
        uint256 vote; // proposal index
        address voterAddress; // to keep track of the voter's address
        bool isRegistered; // to check if the voter is registered
    }

    // Proposal struct to keep track of the proposal's information and vote count
    struct Proposal {
        string name; // name of the proposal
        uint256 voteCount; // number of votes for the proposal
    }

    enum VotingState {
        OPEN,
        CLOSED
    }

    address private immutable i_chairperson; // the address of the chairperson
    mapping(address => voterRecord) private s_voters; // mapping of voters}
    Proposal[] private s_proposals; // array of proposals

    uint256 private s_winningProposalIndex; // index of the winning proposal
    uint256 private s_totalVotes; // total number of votes cast
    VotingState private s_votingState; // current state of the voting process

    uint256 private s_votingDeadline; // timestamp of the voting deadline

    event ProposalCreated(string proposalName); // event emitted when a proposal is created
    event Voted(address voter, uint256 proposalIndex); // event emitted when a vote is cast

    constructor(string[] memory proposalNames, uint256 votingDuration) {
        i_chairperson = msg.sender; // set the chairperson to the address that deploys the contract
        s_votingDeadline = block.timestamp + votingDuration; // set the voting deadline
        s_votingState = VotingState.OPEN; // set the initial voting state to OPEN
        for (uint256 i = 0; i < proposalNames.length; i++) {
            s_proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
        emit ProposalCreated(proposalNames[0]);
    }

    modifier onlyChairperson() {
        if (msg.sender != i_chairperson) {
            revert Ballot__NotChairperson();
        }
        _;
    }

    function registerVoter(address voter) public onlyChairperson {
        if (s_voters[voter].isRegistered) {
            revert Ballot__VoterAlreadyRegistered();
        }

        if (voter == address(0)) {
            revert Ballot__InvalidVoter();
        }

        s_voters[voter].isRegistered = true;
        s_voters[voter].voterAddress = voter;
    }

    function vote(uint256 proposalIndex) public {
        address voter = msg.sender;

        if (block.timestamp > s_votingDeadline) {
            revert Ballot__VotingAlreadyEnded();
        }

        //Check if the voter is registered
        if (!s_voters[voter].isRegistered) {
            revert Ballot__NotRegistered();
        }
        // Check if the voter has already voted
        if (s_voters[voter].hasVoted) {
            revert Ballot__AlreadyVoted();
        }

        //[0,1,2,3,4] proposalIndex = 5
        if (proposalIndex >= s_proposals.length) {
            revert Ballot__InvalidProposal();
        }
        //update the voter's record and the proposal's vote count
        s_voters[voter].hasVoted = true;
        s_voters[voter].vote = proposalIndex;
        s_proposals[proposalIndex].voteCount += 1;

        emit Voted(voter, proposalIndex);
    }

    // function winningProposal()
    //     public
    //     returns (string memory winningProposalName)
    // {
    //     uint256 winningVoteCount = 0;
    //     for (uint256 i = 0; i < s_proposals.length; i++) {
    //         if (s_proposals[i].voteCount > winningVoteCount) {
    //             winningVoteCount = s_proposals[i].voteCount;
    //             s_winningProposalIndex = i;
    //         }
    //     }
    //     winningProposalName = s_proposals[s_winningProposalIndex].name;
    // }

    function finalizeResults() external onlyChairperson {
        if (block.timestamp < s_votingDeadline) {
            revert Ballot__VotingNotEnded();
        }
        if (s_votingState == VotingState.CLOSED) {
            revert Ballot__VotingAlreadyEnded();
        }
        uint256 winningVoteCount = 0;
        for (uint256 i = 0; i < s_proposals.length; i++) {
            if (s_proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = s_proposals[i].voteCount;
                s_winningProposalIndex = i;
            }
        }
        s_votingState = VotingState.CLOSED;
    }

    function winningProposal()
        external
        view
        returns (string memory winningProposalName)
    {
        if (s_votingState != VotingState.CLOSED) {
            revert Ballot__VotingNotEnded();
        }

        winningProposalName = s_proposals[s_winningProposalIndex].name;
    }

    /////GETTER FUNCTIONS/////

    function getChairperson() external view returns (address) {
        return i_chairperson;
    }

    function getProposal(
        uint256 index
    ) external view returns (string memory name, uint256 voteCount) {
        if (index >= s_proposals.length) {
            revert Ballot__InvalidProposal();
        }
        Proposal memory proposal = s_proposals[index];
        return (proposal.name, proposal.voteCount);
    }

    function getVoter(
        address voter
    )
        external
        view
        returns (
            bool hasVoted,
            uint256 votedProposalIndex,
            address voterAddress,
            bool isRegistered
        )
    {
        if (!s_voters[voter].isRegistered) {
            revert Ballot__NotRegistered();
        }
        voterRecord memory record = s_voters[voter];
        return (
            record.hasVoted,
            record.vote,
            record.voterAddress,
            record.isRegistered
        );
    }
}
