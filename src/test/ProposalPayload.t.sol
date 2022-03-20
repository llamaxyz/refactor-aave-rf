// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;
pragma abicoder v2;

// testing libraries
import "ds-test/test.sol";
import "forge-std/console.sol";
import {stdCheats} from "forge-std/stdlib.sol";

// contract dependencies
import "./interfaces/Vm.sol";
import "../interfaces/IAaveGovernanceV2.sol";
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

    address private proposalPayloadAddress;
    address private tokenDistributorAddress;
    address private ecosystemReserveAddress;

    address[] private targets;
    uint256[] private values;
    string[] private signatures;
    bytes[] private calldatas;
    bool[] private withDelegatecalls;
    bytes32 private ipfsHash = 0x0;

    uint256 proposalId;

    IERC20 private constant aWBTC = IERC20(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656);
    IReserveFactorV1 private constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);
    address private constant reserveFactorV2 = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    address private constant emergencyReserve = 0x2fbB0c60a41cB7Ea5323071624dCEAD3d213D0Fa;

    IProtocolDataProvider private constant dataProvider =
        IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    address private constant dpi = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

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
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)
    ];

    uint256[] private balances = [
        26896451,
        239455415285533321239318,
        179497214695,
        1155771700,
        810952180672149368627,
        483375892899443637,
        302200436866856166373,
        690230097270865694228,
        29249800489993423,
        34279670671399439576,
        51433343686459520786,
        650810411734831217
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

        // execute proposal
        aaveGovernanceV2.execute(proposalId);

        // confirm state after
        IAaveGovernanceV2.ProposalState state = aaveGovernanceV2.getProposalState(proposalId);
        assertEq(uint256(state), uint256(IAaveGovernanceV2.ProposalState.Executed), "PROPOSAL_NOT_IN_EXPECTED_STATE");

        // confirm distributions were updated
        (address[] memory newReceivers, uint256[] memory newPercentages) = reserveFactorV1.getDistribution();
        assertEq(newReceivers.length, 1);
        assertEq(newPercentages.length, 1);
        assertEq(newReceivers[0], reserveFactorV2);
        assertEq(newPercentages[0], 100_00);
    }

    function testAssetDistribution() public {
        // cache v2 balances before gov proposal
        uint256[] memory v2OriginalBalances = new uint256[](12);

        for (uint256 i; i < tokens.length; i++) {
            v2OriginalBalances[i] = tokens[i].balanceOf(address(reserveFactorV2));
        }
        uint256 v2EthBalance = address(reserveFactorV2).balance;

        // check pre-execution state
        for (uint256 i; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(reserveFactorV1)), balances[i]);
        }

        uint256 v1EthBalance = address(reserveFactorV1).balance;
        assertEq(v1EthBalance, 104432825860028928474);

        // execute proposal
        aaveGovernanceV2.execute(proposalId);

        // confirm state after
        IAaveGovernanceV2.ProposalState state = aaveGovernanceV2.getProposalState(proposalId);
        assertEq(uint256(state), uint256(IAaveGovernanceV2.ProposalState.Executed), "PROPOSAL_NOT_IN_EXPECTED_STATE");

        // check that v1 is empty and v2 has all funds
        for (uint256 i; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(reserveFactorV1)), 0);
        }
        uint256 v1EthNewBalance = address(reserveFactorV1).balance;
        assertEq(v1EthNewBalance, 0);

        for (uint256 i; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(reserveFactorV2)), v2OriginalBalances[i] + balances[i]);
        }
        assertEq(address(reserveFactorV2).balance, v1EthBalance + v2EthBalance);
    }

    function testDpiBorrowing() public {
        // execute proposal
        aaveGovernanceV2.execute(proposalId);

        // confirm state after
        IAaveGovernanceV2.ProposalState state = aaveGovernanceV2.getProposalState(proposalId);
        assertEq(uint256(state), uint256(IAaveGovernanceV2.ProposalState.Executed), "PROPOSAL_NOT_IN_EXPECTED_STATE");

        // confirm borrow enabled but stable disabled
        (, , , , , , bool borrowEnabled, bool stableBorrowEnabled, , ) = dataProvider.getReserveConfigurationData(dpi);
        assertTrue(borrowEnabled, "DPI_BORROW_NOT_ENABLED");
        assertTrue(!stableBorrowEnabled, "DPI_STABLE_BORROW_ENABLED");
    }

    /*******************************************************************************/
    /******************     Aave Gov Process - Create Proposal     *****************/
    /*******************************************************************************/

    function _createProposal() public {
        // Deploy TokenDistributor implementation contract
        tokenDistributorAddress = deployCode("TokenDistributor.sol:TokenDistributor");
        ecosystemReserveAddress = deployCode("AaveEcosystemReserve.sol:AaveEcosystemReserve");

        ProposalPayload proposalPayload = new ProposalPayload(tokenDistributorAddress, ecosystemReserveAddress);
        proposalPayloadAddress = address(proposalPayload);

        bytes memory emptyBytes;

        targets.push(proposalPayloadAddress);
        values.push(0);
        signatures.push("execute()");
        calldatas.push(emptyBytes);
        withDelegatecalls.push(true);

        targets.push(proposalPayloadAddress);
        values.push(0);
        signatures.push("executeWithoutDelegate()");
        calldatas.push(emptyBytes);
        withDelegatecalls.push(false);

        vm.prank(aaveWhales[0]);
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
