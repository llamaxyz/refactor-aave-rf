// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;
pragma abicoder v2;

// testing libraries
import "ds-test/test.sol";
import "forge-std/console.sol";
import {stdCheats} from "forge-std/stdlib.sol";
import {Vm} from "forge-std/Vm.sol";

// contract dependencies
import "../interfaces/IAaveGovernanceV2.sol";
import "../interfaces/IEcosystemReserveController.sol";
import "../interfaces/IExecutorWithTimelock.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IProtocolDataProvider.sol";

import "../ProposalPayload.sol";

contract ProposalPayloadTest is DSTest, stdCheats {
    Vm vm = Vm(HEVM_ADDRESS);

    address aaveTokenAddress = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    IERC20 aaveToken = IERC20(aaveTokenAddress);

    address aaveGovernanceAddress = 0xEC568fffba86c094cf06b22134B23074DFE2252c;
    address aaveGovernanceShortExecutor = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    IAaveGovernanceV2 aaveGovernanceV2 = IAaveGovernanceV2(aaveGovernanceAddress);
    IExecutorWithTimelock shortExecutor = IExecutorWithTimelock(aaveGovernanceShortExecutor);

    address[] private aaveWhales;
    address private llamaProposer = 0x5B3bFfC0bcF8D4cAEC873fDcF719F60725767c98;

    address private proposalPayloadAddress;
    address private tokenDistributorAddress;

    address[] private targets;
    uint256[] private values;
    string[] private signatures;
    bytes[] private calldatas;
    bool[] private withDelegatecalls;
    bytes32 private ipfsHash = 0x0;

    uint256 proposalId;

    IReserveFactorV1 private constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);
    address private constant reserveFactorV2 = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    address private constant emergencyReserve = 0x2fbB0c60a41cB7Ea5323071624dCEAD3d213D0Fa;
    IAddressesProvider private constant addressProvider =
        IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    IEcosystemReserveController private controller =
        IEcosystemReserveController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

    IProtocolDataProvider private constant dataProvider =
        IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    address private constant dpi = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

    address private constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant originalV1EthBalance = 104439454875477877610;

    IERC20[] private tokens = [
        IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599),
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F),
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7),
        IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200),
        IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2),
        IERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942),
        IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53),
        IERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e),
        IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA),
        IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984),
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9),
        IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03),
        IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF),
        IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)
    ];

    uint256[] private balances = [
        26896452,
        240207569143888085646039,
        179515048641,
        1156029586,
        810952180672149368627,
        490095716250032041,
        302200436866856166373,
        690230097270865694228,
        29249891848468059,
        34332040401098059151,
        51433343686459520786,
        650810411734831217,
        97625888338530404906,
        250506184215430361840,
        22156845112342110874
    ];

    function setUp() public {
        // aave whales may need to be updated based on the block being used
        // these are sometimes exchange accounts or whale who move their funds

        // select large holders here: https://etherscan.io/token/0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9#balances
        aaveWhales.push(0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8);
        aaveWhales.push(0x26a78D5b6d7a7acEEDD1e6eE3229b372A624d8b7);
        aaveWhales.push(0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2);

        // create proposal is configured to deploy a Payload contract and call execute() as a delegatecall
        // most proposals can use this format - you likely will not have to update this
        _createProposal();

        // these are generic steps for all proposals - no updates required
        _voteOnProposal();
        _skipVotingPeriod();
        _queueProposal();
        _skipQueuePeriod();
    }

    function testTokenDistributorUpgrade() public {
        // get state before proposal execution
        (address[] memory receivers, uint256[] memory percentages) = reserveFactorV1.getDistribution();

        // check pre-proposal state
        assertEq(receivers[0], reserveFactorV2);
        assertEq(receivers[1], emergencyReserve);
        assertEq(percentages[0], 80_00);
        assertEq(percentages[1], 20_00);

        _executeProposal();

        // confirm distributions were updated
        (address[] memory newReceivers, uint256[] memory newPercentages) = reserveFactorV1.getDistribution();
        assertEq(newReceivers.length, 1);
        assertEq(newPercentages.length, 1);
        assertEq(newReceivers[0], reserveFactorV2);
        assertEq(newPercentages[0], 100_00);
    }

    function testAssetDistribution() public {
        // cache v2 balances before gov proposal
        uint256[] memory v2OriginalBalances = new uint256[](15);

        for (uint256 i; i < tokens.length; i++) {
            v2OriginalBalances[i] = tokens[i].balanceOf(reserveFactorV2);
        }
        uint256 v2EthBalance = reserveFactorV2.balance;

        // check pre-execution state
        for (uint256 i; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(reserveFactorV1)), balances[i]);
        }

        uint256 v1EthBalance = address(reserveFactorV1).balance;
        assertEq(v1EthBalance, originalV1EthBalance);

        _executeProposal();

        // check that v1 is empty and v2 has all funds
        for (uint256 i; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(reserveFactorV1)), 0);
        }
        uint256 v1EthNewBalance = address(reserveFactorV1).balance;
        assertEq(v1EthNewBalance, 0);

        for (uint256 i; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(reserveFactorV2), v2OriginalBalances[i] + balances[i]);
        }
        assertEq(reserveFactorV2.balance, v1EthBalance + v2EthBalance);
    }

    function testDistributorUpdated() public {
        // confirm token distributor is v1 reserve
        assertEq(addressProvider.getTokenDistributor(), address(reserveFactorV1));

        _executeProposal();

        // check token distributor was updated to v2 reserve
        assertEq(addressProvider.getTokenDistributor(), reserveFactorV2);
    }

    function testDpiBorrowing() public {
        _executeProposal();

        // confirm borrow enabled but stable disabled
        (, , , , , , bool borrowEnabled, bool stableBorrowEnabled, , ) = dataProvider.getReserveConfigurationData(dpi);
        assertTrue(borrowEnabled, "DPI_BORROW_NOT_ENABLED");
        assertTrue(!stableBorrowEnabled, "DPI_STABLE_BORROW_ENABLED");
    }

    function testEcosystemReserveETH() public {
        _executeProposal();
        // check ecosystem reserve can receive eth
        (bool success2, ) = reserveFactorV2.call{value: 100 ether}("");
        assertTrue(success2, "DID_NOT_RECEIVED_ETHER");

        // check ecosystem reserve can transfer eth after proposal
        address randomAddr = 0x00Be3826e98a5e26C022811001e740Ca00e2D01f;
        uint256 v1EthBalance = 104439454875477877610;
        vm.prank(address(aaveGovernanceShortExecutor));
        controller.transfer(address(reserveFactorV2), ethAddress, randomAddr, 50 ether);
        assertEq(randomAddr.balance, 50 ether);
        assertEq(reserveFactorV2.balance, v1EthBalance + 50 ether);
    }

    function _executeProposal() public {
        // execute proposal
        aaveGovernanceV2.execute(proposalId);

        // confirm state after
        IAaveGovernanceV2.ProposalState state = aaveGovernanceV2.getProposalState(proposalId);
        assertEq(uint256(state), uint256(IAaveGovernanceV2.ProposalState.Executed), "PROPOSAL_NOT_IN_EXPECTED_STATE");
    }

    /*******************************************************************************/
    /******************     Aave Gov Process - Create Proposal     *****************/
    /*******************************************************************************/

    function _createProposal() public {
        // Deploy TokenDistributor implementation contract
        tokenDistributorAddress = deployCode("TokenDistributor.sol:TokenDistributor");

        ProposalPayload proposalPayload = new ProposalPayload(tokenDistributorAddress);
        proposalPayloadAddress = address(proposalPayload);

        bytes memory emptyBytes;

        targets.push(proposalPayloadAddress);
        values.push(0);
        signatures.push("execute()");
        calldatas.push(emptyBytes);
        withDelegatecalls.push(true);

        targets.push(proposalPayloadAddress);
        values.push(0);
        signatures.push("distributeTokens()");
        calldatas.push(emptyBytes);
        withDelegatecalls.push(false);

        vm.prank(llamaProposer);
        aaveGovernanceV2.create(shortExecutor, targets, values, signatures, calldatas, withDelegatecalls, ipfsHash);
        proposalId = aaveGovernanceV2.getProposalsCount() - 1;
    }

    /*******************************************************************************/
    /***************     Aave Gov Process - No Updates Required      ***************/
    /*******************************************************************************/

    function _voteOnProposal() public {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposal = aaveGovernanceV2.getProposalById(proposalId);
        vm.roll(proposal.startBlock + 1);
        for (uint256 i; i < aaveWhales.length; i++) {
            vm.prank(aaveWhales[i]);
            aaveGovernanceV2.submitVote(proposalId, true);
        }
    }

    function _skipVotingPeriod() public {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposal = aaveGovernanceV2.getProposalById(proposalId);
        vm.roll(proposal.endBlock + 1);
    }

    function _queueProposal() public {
        aaveGovernanceV2.queue(proposalId);
    }

    function _skipQueuePeriod() public {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposal = aaveGovernanceV2.getProposalById(proposalId);
        vm.warp(proposal.executionTime + 1);
    }

    function testSetup() public {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposal = aaveGovernanceV2.getProposalById(proposalId);
        assertEq(proposalPayloadAddress, proposal.targets[0], "TARGET_IS_NOT_PAYLOAD");

        IAaveGovernanceV2.ProposalState state = aaveGovernanceV2.getProposalState(proposalId);
        assertEq(uint256(state), uint256(IAaveGovernanceV2.ProposalState.Queued), "PROPOSAL_NOT_IN_EXPECTED_STATE");
    }
}
