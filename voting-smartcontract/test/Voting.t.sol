// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {Ballot} from "../src/Voting.sol";
import {DeployVoting} from "../script/DeployVoting.s.sol";

contract BallotTest is Test {
    Ballot public ballot;
    address public USER = makeAddr("user");

    function setUp() public {
        DeployVoting deployer = new DeployVoting();
        ballot = deployer.run();
    }

    // Test cases for the Ballot contract will go here

    function testChairpersonIsOwner() public view {
        address chairperson = ballot.getChairperson();
        assertEq(chairperson, msg.sender);
    }

    modifier onlyChairperson() {
        if (msg.sender != ballot.getChairperson()) {
            revert Ballot.Ballot__NotChairperson();
        }
        _;
    }

    function testRegisterVoterNotChairperson() public {
        vm.prank(USER);
        vm.expectRevert(Ballot.Ballot__NotChairperson.selector);
        ballot.registerVoter(USER);
    }

    function testRegisterVoterWithInvalidAddressReverts() public {
        vm.prank(ballot.getChairperson());
        vm.expectRevert(Ballot.Ballot__InvalidVoter.selector);
        ballot.registerVoter(address(0));
    }

    function testRegisterVoterRevertsIfAlreadyRegistered() public {
        //Arrange
        vm.prank(ballot.getChairperson());
        //Act
        ballot.registerVoter(USER);
        vm.prank(ballot.getChairperson());
        //Assert
        vm.expectRevert(Ballot.Ballot__VoterAlreadyRegistered.selector);
        ballot.registerVoter(USER);
    }

    function testRegisterVoterRevertsIfVoterAlreadyVoted() public {
        //Arrange
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(USER);
        //Act
        vm.prank(USER);
        ballot.vote(0);
        //Assert
        vm.prank(ballot.getChairperson());
        vm.expectRevert(Ballot.Ballot__VoterAlreadyRegistered.selector);
        ballot.registerVoter(USER);
    }

    function testChairPersonCanRegisterVoter() public {
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(USER);
        (, , , bool isRegistered) = ballot.getVoter(USER);
        assertTrue(isRegistered);
    }

    function testVotingAfterDeadlineReverts() public {
        //Arrange
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(USER);
        //Act
        vm.warp(block.timestamp + 2 days);
        //Assert
        vm.prank(USER);
        vm.expectRevert(Ballot.Ballot__VotingAlreadyEnded.selector);
        ballot.vote(0);
    }

    function testVotingRevertsIfVoterNotRegistered() public {
        //Act
        vm.prank(USER);
        vm.expectRevert(Ballot.Ballot__NotRegistered.selector);
        ballot.vote(0);
    }

    function testIfVoterAlreadyVotedReverts() public {
        //Arrange
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(USER);
        //Act
        vm.prank(USER);
        ballot.vote(0);
        //Assert
        vm.prank(USER);
        vm.expectRevert(Ballot.Ballot__AlreadyVoted.selector);
        ballot.vote(0);
    }

    function testIfProposalIndexInvalidReverts() public {
        //Arrange
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(USER);
        //Act
        vm.prank(USER);
        vm.expectRevert(Ballot.Ballot__InvalidProposal.selector);
        ballot.vote(5);
    }

    function testSuccessfulVote() public {
        //Arrange
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(USER);
        //Act
        vm.prank(USER);
        ballot.vote(1);
        //Assert
        (, uint256 vote, , ) = ballot.getVoter(USER);
        assertEq(vote, 1);
    }

    function testFinalVotingResults() public {
        //Arrange
        address voter1 = makeAddr("voter1");
        address voter2 = makeAddr("voter2");
        address voter3 = makeAddr("voter3");

        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter1);
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter2);
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter3);

        //Act
        vm.prank(voter1);
        ballot.vote(0);
        vm.prank(voter2);
        ballot.vote(1);
        vm.prank(voter3);
        ballot.vote(1);

        //Assert
        (string memory proposalName, uint256 voteCount) = ballot.getProposal(0);
        assertEq(proposalName, "Proposal 1");
        assertEq(voteCount, 1);

        (proposalName, voteCount) = ballot.getProposal(1);
        assertEq(proposalName, "Proposal 2");
        assertEq(voteCount, 2);

        (proposalName, voteCount) = ballot.getProposal(2);
        assertEq(proposalName, "Proposal 3");
        assertEq(voteCount, 0);
    }

    function testFinalResultRevertsIfVotingNotEnded() public {
        //Arrange
        address voter1 = makeAddr("voter1");
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter1);
        vm.prank(voter1);
        ballot.vote(0);

        //Act
        vm.prank(ballot.getChairperson());
        vm.expectRevert(Ballot.Ballot__VotingNotEnded.selector);
        ballot.finalizeResults();
    }

    function testFinalResultRevertsIfVotingEnded() public {
        //Arrange
        address voter1 = makeAddr("voter1");
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter1);
        vm.prank(voter1);
        ballot.vote(0);
        //Act
        vm.warp(block.timestamp + 2 days);

        //First call to finalize results should succeed
        // First call: should succeed and close voting
        vm.prank(ballot.getChairperson());
        ballot.finalizeResults();
        //second call should revert since voting is already closed
        vm.prank(ballot.getChairperson());
        vm.expectRevert(Ballot.Ballot__VotingAlreadyEnded.selector);
        ballot.finalizeResults();
    }

    function testWinningProposalRevertsIfVotingNotEnded() public {
        //Arrange
        address voter1 = makeAddr("voter1");
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter1);
        vm.prank(voter1);
        ballot.vote(0);

        //Act
        vm.prank(ballot.getChairperson());
        vm.expectRevert(Ballot.Ballot__VotingNotEnded.selector);
        ballot.winningProposal();
    }

    function testWinningProposal() public {
        //Arrange
        address voter1 = makeAddr("voter1");
        address voter2 = makeAddr("voter2");
        address voter3 = makeAddr("voter3");

        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter1);
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter2);
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(voter3);

        //Act
        vm.prank(voter1);
        ballot.vote(0);
        vm.prank(voter2);
        ballot.vote(1);
        vm.prank(voter3);
        ballot.vote(1);

        //Assert
        vm.warp(block.timestamp + 2 days);
        vm.prank(ballot.getChairperson());
        ballot.finalizeResults();
        string memory winningProposalName = ballot.winningProposal();
        assertEq(winningProposalName, "Proposal 2");
    }

    function testGetVoterRecord() public {
        //Arrange
        vm.prank(ballot.getChairperson());
        ballot.registerVoter(USER);
        //Act
        vm.prank(USER);
        ballot.vote(1);
        //Assert
        (
            bool hasVoted, // to check if the voter has already voted
            uint256 vote, // proposal index
            address voterAddress, // to keep track of the voter's address
            bool isRegistered
        ) = ballot.getVoter(USER);
        assertEq(voterAddress, USER);
        assertEq(vote, 1);
        assertTrue(hasVoted);
        assertTrue(isRegistered);
    }

    function testInvalidProposalIndexInGetProposal() public {
        //Act
        vm.expectRevert(Ballot.Ballot__InvalidProposal.selector);
        ballot.getProposal(5);
    }

    function testGetVoterRevertsIfVoterNotRegistered() public {
        //Act
        vm.expectRevert(Ballot.Ballot__NotRegistered.selector);
        ballot.getVoter(USER);
    }

    // function testFinalVotingResultsCanOnlyBeCalledByChairperson() public {
    //     //Arrange
    //     address voter1 = makeAddr("voter1");
    //     address voter2 = makeAddr("voter2");
    //     address voter3 = makeAddr("voter3");
    //     address voter4 = makeAddr("voter4");
    //     address voter5 = makeAddr("voter5");

    //     vm.prank(ballot.getChairperson());
    //     ballot.registerVoter(voter1);
    //     vm.prank(ballot.getChairperson());
    //     ballot.registerVoter(voter2);
    //     vm.prank(ballot.getChairperson());
    //     ballot.registerVoter(voter3);
    //     vm.prank(ballot.getChairperson());
    //     ballot.registerVoter(voter4);
    //     vm.prank(ballot.getChairperson());
    //     ballot.registerVoter(voter5);

    //     //Act
    //     vm.prank(voter1);
    //     ballot.vote(0);
    //     vm.prank(voter2);
    //     ballot.vote(1);
    //     vm.prank(voter3);
    //     ballot.vote(1);
    //     vm.prank(voter4);
    //     ballot.vote(0);
    //     vm.prank(voter5);
    //     ballot.vote(0);

    //     //Assert
    //     (string memory proposalName, uint256 voteCount) = ballot.getProposal(0);
    //     assertEq(proposalName, "Proposal 1");
    //     assertEq(voteCount, 1);

    //     (proposalName, voteCount) = ballot.getProposal(1);
    //     assertEq(proposalName, "Proposal 2");
    //     assertEq(voteCount, 2);

    //     (proposalName, voteCount) = ballot.getProposal(2);
    //     assertEq(proposalName, "Proposal 3");
    //     assertEq(voteCount, 0);
    // }
}
