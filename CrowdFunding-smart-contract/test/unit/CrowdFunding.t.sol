// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {CrowdFunding} from "src/CrowdFunding.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployCrowdFunding} from "script/DeployCrowdFunding.s.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract CrowdFundingTest is Test {
    CrowdFunding public crowdFunding;
    HelperConfig public helperConfig;
    address USER = makeAddr("user");
    uint160 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 public Gas_Price = 1;

    event ContributionReceived(address indexed contributor, uint256 amount);

    function setUp() public {
        DeployCrowdFunding deployer = new DeployCrowdFunding();
        crowdFunding = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testContributionStateIsOpen() public view {
        assertEq(
            uint256(crowdFunding.getCrowdFundingState()),
            uint256(CrowdFunding.CrowdFundingState.OPEN)
        );
    }

    function testMinimumContributionIsFiveDollars() public view {
        assertEq(crowdFunding.MINIMUM_CONTRIBUTION(), 5 * 10e18);
    }

    function testTargetAmountIsOneEther() public view {
        assertEq(crowdFunding.TARGET_AMOUNT(), 1 ether);
    }

    function testOwnerIsMsgSender() public view {
        address owner = crowdFunding.getOwner();
        assertEq(owner, msg.sender);
    }

    function testContributionRevertsIfBelowMinimumContribution() public {
        // vm.prank(USER);
        vm.expectRevert(
            CrowdFunding.CrowdFunding__InsufficientContribution.selector
        );
        crowdFunding.contribute();
    }

    function testContributionReversIfCrowdFundingClosed() public {
        // vm.prank(crowdFunding.getOwner());
        //Arrange
        uint256 deadline = crowdFunding.getDeadline();
        //Assume the deadline has passed
        vm.warp(deadline + 2 days);
        //Act / Assert

        vm.expectRevert(CrowdFunding.CrowdFunding__CrowdFundingClosed.selector);
        crowdFunding.contribute{value: SEND_VALUE}();
    }

    function testRepeatedContributionIncreasesAmountButDoesNotAddDuplicateContributorAddress()
        public
    {
        // Arrange
        vm.deal(USER, 10 ether); // ensure USER has ETH

        // --- First contribution ---
        vm.prank(USER);
        vm.expectEmit(true, true, true, false, address(crowdFunding));
        emit ContributionReceived(USER, SEND_VALUE);
        crowdFunding.contribute{value: SEND_VALUE}();

        // Capture first state (after first contribution)
        uint256 firstAmount = crowdFunding.contributorData(USER);
        uint256 firstLength = crowdFunding.getAllContributors().length;

        // --- Second contribution ---
        vm.prank(USER);
        vm.expectEmit(true, true, true, false, address(crowdFunding));
        emit ContributionReceived(USER, SEND_VALUE);
        crowdFunding.contribute{value: SEND_VALUE}();

        // Capture updated state (after second contribution)
        uint256 updatedAmount = crowdFunding.contributorData(USER);
        uint256 updatedLength = crowdFunding.getAllContributors().length;

        // Assert — total amount increased by both contributions
        assertEq(
            updatedAmount,
            firstAmount + SEND_VALUE,
            "Should add to previous contribution"
        );

        // Assert — contributor list length unchanged
        assertEq(
            updatedLength,
            firstLength,
            "Should not push duplicate contributor"
        );
    }

    function testContributionUpdatesDataStructures() public {
        vm.prank(USER);
        vm.expectEmit(true, true, true, false, address(crowdFunding));
        emit ContributionReceived(USER, SEND_VALUE);
        crowdFunding.contribute{value: SEND_VALUE}();
        uint256 amountContributed = crowdFunding.getAmountContributed(USER);
        assertEq(amountContributed, SEND_VALUE);
    }

    function testContributionAddsToContributorsArray() public {
        vm.prank(USER);
        crowdFunding.contribute{value: SEND_VALUE}();
        address[] memory contributors = crowdFunding.getAllContributors();
        assertEq(contributors[0], USER);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER);
        vm.expectRevert(CrowdFunding.CrowdFunding__NotOwner.selector);
        crowdFunding.withdraw();
    }

    function testRefundRevertsIfGoalAlreadyReached() public {
        vm.prank(USER);
        crowdFunding.contribute{value: 1 ether}();
        vm.expectRevert(CrowdFunding.CrowdFunding__GoalAlreadyReached.selector);
        crowdFunding.refund();
    }

    function testRefundRevertsIfNoContributions() public {
        vm.expectRevert(CrowdFunding.CrowdFunding__NoContributions.selector);
        crowdFunding.refund();
    }

    function testGetAllContributors() public {
        vm.prank(USER);
        crowdFunding.contribute{value: SEND_VALUE}();
        address[] memory contributors = crowdFunding.getAllContributors();
        assertEq(contributors.length, 1);
        // assertEq(contributors[0], USER);
    }

    function testToGetBalance() public {
        vm.prank(USER);
        crowdFunding.contribute{value: SEND_VALUE}();
        uint256 balance = crowdFunding.getBalance();
        assertEq(balance, SEND_VALUE);
    }

    function testWithdrawRevertsIfGoalNotReached() public {
        vm.prank(USER);
        crowdFunding.contribute{value: SEND_VALUE}();
        vm.prank(crowdFunding.getOwner());
        vm.expectRevert(CrowdFunding.CrowdFunding__GoalNotReached.selector);
        crowdFunding.withdraw();
    }

    modifier contributeFunds() {
        vm.prank(USER);
        crowdFunding.contribute{value: 1 ether}();
        _;
    }

    // function testSingleContributorCanRefund() public {
    //     uint256 startingBalance = USER.balance;
    //     vm.prank(USER);
    //     crowdFunding.contribute{value: SEND_VALUE}();
    //     vm.expectRevert(CrowdFunding.CrowdFunding__NoContributions.selector);
    //     crowdFunding.refund();
    //     uint256 endingBalance = USER.balance;
    //     assertEq(endingBalance, startingBalance + SEND_VALUE);
    // }

    function testSingleContributorCanRefund() public {
        uint256 startingBalance = USER.balance;
        vm.prank(USER);
        crowdFunding.contribute{value: SEND_VALUE}();
        vm.prank(USER);
        crowdFunding.refund();
        uint256 endingBalance = USER.balance;
        assertEq(endingBalance, startingBalance);
    }

    function testSingleWithdraw() public contributeFunds {
        //Arrange
        uint256 startingOwnerBalance = crowdFunding.getOwner().balance;
        uint256 startingCrowdFundingBalance = address(crowdFunding).balance;

        vm.txGasPrice(Gas_Price);
        uint256 gasStart = gasleft();

        //Act
        vm.prank(crowdFunding.getOwner());

        crowdFunding.withdraw();
        vm.stopPrank();

        //Assert
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        uint256 endingOwnerBalance = crowdFunding.getOwner().balance;
        uint256 endingCrowdFundingBalance = address(crowdFunding).balance;
        assertEq(endingCrowdFundingBalance, 0);
        assertEq(
            startingCrowdFundingBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testGetCrowdFundingState() public view {
        CrowdFunding.CrowdFundingState state = crowdFunding
            .getCrowdFundingState();
        assertEq(uint256(state), uint256(CrowdFunding.CrowdFundingState.OPEN));
    }

    function testGetDeadline() public view {
        uint256 deadline = crowdFunding.getDeadline();
        assertGt(deadline, block.timestamp);
    }

    function testGetAmountContributed() public contributeFunds {
        uint256 amount = crowdFunding.getAmountContributed(USER);
        assertEq(amount, 1 ether);
    }

    function testHelperConfigVaraiable() public {
        // HelperConfig helperConfig = new HelperConfig();
        helperConfig = new HelperConfig();
        assertEq(helperConfig.DECIMALS(), 8);
        assertEq(helperConfig.INITIAL_PRICE(), 2000e8);
    }

    function testSepoliaConfig() public {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory sepoliaConfig = helperConfig
            .getSepoliaEthConfig();
        assertEq(
            sepoliaConfig.crowdFunding,
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
    }

    function testCreatesMockV3AggregatorIfNotSet() public {
        // Act: call the function to create config
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getOrCreateAnvilEthConfig();

        // Assert: returned address should not be zero
        assertTrue(
            config.crowdFunding != address(0),
            "crowdFunding should not be zero"
        );

        // Assert: address should point to a valid MockV3Aggregator
        MockV3Aggregator mock = MockV3Aggregator(config.crowdFunding);

        assertEq(mock.decimals(), 8, "Incorrect decimals");
        assertEq(mock.latestAnswer(), 2000e8, "Incorrect initial price");
    }
}
