// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IVault} from "./interfaces/IVault.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import "./interfaces/IAddressesProvider.sol";
import "./interfaces/IReserveFactorV1.sol";
import "./interfaces/IControllerV2Collector.sol";

/// @title Refactor AAVE Reserve Factor
/// @author Austin Green
/// @notice Provides an execute function for Aave governance to refactor its reserve factor.
contract Refactor {
    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice AAVE's V2 Reserve Factor.
    address private constant reserveFactorV2 = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    /// @notice Provides the logic for the V2 address to set ERC20 approvals.
    /// @notice Approvals only be initiated by AAVE's governance executor.
    IControllerV2Collector private constant collector =
        IControllerV2Collector(0x7AB1e5c406F36FE20Ce7eBa528E182903CA8bFC7);

    /// @notice Provides address mapping for AAVE.
    IAddressesProvider private constant addressProvider =
        IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    /// @notice AAVE's V1 Reserve Factor.
    IReserveFactorV1 private constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);

    /// @notice The stable BTC balancer pool.
    /// @dev LP token symbol is `staBAL3-BTC`
    IVault private constant balancerBtcPool = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    /// @notice Stable BTC balancer pool id.
    bytes32 private constant balancerBtcPoolId = 0xfeadd389a5c427952d8fdb8057d6c8ba1156cc56000000000000000000000066;

    /// @notice AAVE's wrapped BTC lending pool.
    ILendingPool private constant wbtcLendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    /// @notice awBtc token.
    ERC20 private constant awBtc = ERC20(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656);

    /// @notice wBtc token.
    address private constant wBtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /*///////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    address[] private tokenAddresses = [
        wBtc,
        /// @notice DAI
        0x6B175474E89094C44Da98b954EedeAC495271d0F,
        /// @notice USDC
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        /// @notice USDT
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        /// @notice KNC
        0xdd974D5C2e2928deA5F71b9825b8b646686BD200,
        /// @notice MKR
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
        /// @notice MANA
        0x0F5D2fB29fb7d3CFeE444a200298f468908cC942,
        /// @notice BUSD
        0x4Fabb145d64652a948d72533023f6E7A623C7C53,
        /// @notice YFI
        0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
        /// @notice LINK
        0x514910771AF9Ca656af840dff83E8264EcF986CA,
        /// @notice UNI
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
        /// @notice AAVE
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
    ];

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Distribute V1 RF to V2 RF
        // addressProvider.setTokenDistributor(reserveFactorV2);
        // address[] memory tokens = tokenAddresses;
        // reserveFactorV1.distribute(tokens);

        // Approve this contract to move assets on v2's behalf
        uint256 tokenLength = tokenAddresses.length;
        for (uint256 i = 0; i < tokenLength; i++) {
            collector.approve(tokenAddresses[i], address(this), ERC20(tokenAddresses[i]).balanceOf(reserveFactorV2));
        }

        // Redeem all a tokens for underlying ERC-20s
        // TODO: Implement transfer aTokens to contract and implement withdrawals
        wbtcLendingPool.withdraw(wBtc, awBtc.balanceOf(reserveFactorV2), reserveFactorV2);

        // Redeem and Deposit wBTC in balancer btc vault
        // IVault.JoinPoolRequest request = IVault.JoinPoolRequest([wBtc], [10], );
        // balancerBtcPool.joinPool(balancerBtcPoolId, reserveFactorV2, reserveFactorV2);
    }
}
