// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Test} from "forge-std/Test.sol";
import {CrowdFunding} from "src/CrowdFunding.sol";
import {DeployCrowdFunding} from "script/DeployCrowdFunding.s.sol";
import {FundCrowdFunding, WithdrawCrowdFunding} from "script/Interraction.s.sol";

contract Interraction is Test {
    address USER = makeAddr("user");
    uint256 SEND_VALUE = 1 ether;
    uint160 public constant USER_NUMBER = 50;
    uint256 public constant STARTING_BALANCE = 0.1 ether;
    uint256 constant GAS_PRICE = 1;
    event ContributionReceived(address indexed contributor, uint256 amount);

    CrowdFunding crowdFunding;

    function setUp() public {
        DeployCrowdFunding deployer = new DeployCrowdFunding();
        crowdFunding = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    // function testFundCrowdFunding() public {
    //     fundCrowdFundingScript.fundCrowdfunding(address(crowdFunding));
    //     assert(crowdFunding.contributorData(address(this)) == 0.1 ether);
    // }

    function testContributeAndWithdrawFromCrowdFunding() public {
        FundCrowdFunding fundCrowdFundingScript = new FundCrowdFunding();
        fundCrowdFundingScript.fundCrowdfunding(address(crowdFunding));
        emit ContributionReceived(address(this), SEND_VALUE);

        WithdrawCrowdFunding withdrawCrowdFundingScript = new WithdrawCrowdFunding();
        withdrawCrowdFundingScript.withdrawFromCrowdFunding(
            address(crowdFunding)
        );

        assertEq(address(crowdFunding).balance, 0);
    }

    // function testFundScriptRevertsWhenScriptHasNoBalance() public {
    //     FundCrowdFunding fundScript = new FundCrowdFunding();
    //     // script has no balance -> its internal contribute{value: FUND_AMOUNT} will fail
    //     vm.expectRevert(
    //         CrowdFunding.CrowdFunding__InsufficientContribution.selector
    //     );
    //     fundScript.fundCrowdfunding(address(crowdFunding));
    // }
}
