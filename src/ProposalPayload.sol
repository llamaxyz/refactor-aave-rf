// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./interfaces/IReserveFactorV1.sol";
import "./interfaces/IEcosystemReserve.sol";
import "./interfaces/IControllerV2Collector.sol";
import "./interfaces/IAddressesProvider.sol";

/// @title Payload to refactor AAVE Reserve Factor
/// @author Austin Green
/// @notice Provides an execute function for Aave governance to refactor its reserve factor.
contract ProposalPayload {
    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice wBtc token.
    address private constant wBtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /// @notice dai token.
    address private constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /// @notice usdc token.
    address private constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// @notice usdt token.
    address private constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @notice AAVE's V1 Reserve Factor.
    IReserveFactorV1 private constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);

    /// @notice AAVE's V2 Reserve Factor.
    IEcosystemReserve private constant reserveFactorV2 = IEcosystemReserve(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c);

    /// @notice Provides the logic for the V2 address to set ERC20 approvals.
    /// @notice Approvals only be initiated by AAVE's governance executor.
    IControllerV2Collector private constant collectorController =
        IControllerV2Collector(0x7AB1e5c406F36FE20Ce7eBa528E182903CA8bFC7);

    /// @notice Provides address mapping for AAVE.
    IAddressesProvider private constant addressProvider =
        IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    /// @notice Token distributor implementation contract.
    address private immutable tokenDistributorImpl;

    /// @notice Ecosystem Reserve implementation contract.
    address private immutable ecosystemReserveImpl;

    // Just including this for testing purposes, we'll have the address of the new impl before deploying
    constructor(address _tokenDistributorImpl, address _ecosystemReserveImpl) {
        tokenDistributorImpl = _tokenDistributorImpl;
        ecosystemReserveImpl = _ecosystemReserveImpl;
    }

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Upgrade to new implementation contract and direct all funds to v2
        address[] memory receivers = new address[](1);
        receivers[0] = address(reserveFactorV2);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100_00;

        reserveFactorV1.upgradeToAndCall(
            tokenDistributorImpl,
            abi.encodeWithSignature("initialize(address[],uint256[])", receivers, amounts)
        );

        // Upgrade to new implementation contract that has ability to transfer ETH
        reserveFactorV2.upgradeToAndCall(
            ecosystemReserveImpl,
            abi.encodeWithSignature("initialize(address)", address(collectorController))
        );

        // Set token distributor for AAVE v1 to V2 RF
        addressProvider.setTokenDistributor(address(reserveFactorV2));

        // Distribute all tokens with meaningful balances to v2
        address[] memory tokenAddresses = new address[](12);
        tokenAddresses[0] = wBtc;
        tokenAddresses[1] = dai;
        tokenAddresses[2] = usdc;
        tokenAddresses[3] = usdt;
        tokenAddresses[4] = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200; // KNC
        tokenAddresses[5] = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2; // MKR
        tokenAddresses[6] = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942; // MANA
        tokenAddresses[7] = 0x4Fabb145d64652a948d72533023f6E7A623C7C53; // BUSD
        tokenAddresses[8] = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e; // YFI
        tokenAddresses[9] = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // LINK
        tokenAddresses[10] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI
        tokenAddresses[11] = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9; // AAVE
        reserveFactorV1.distribute(tokenAddresses);
    }
}
