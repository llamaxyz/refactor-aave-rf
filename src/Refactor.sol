// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {IVault} from "@balancer/vault/contracts/interfaces/IVault.sol";
import {ILendingPool} from "@aave/interfaces/ILendingPool.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import "./interfaces/IAddressesProvider.sol";
import "./interfaces/IReserveFactorV1.sol";
import "./interfaces/IControllerV2Collector.sol";

contract Refactor {
    address public constant reserveFactorV2 = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    IControllerV2Collector public constant collector =
        IControllerV2Collector(0x7AB1e5c406F36FE20Ce7eBa528E182903CA8bFC7);
    IAddressesProvider public constant addressProvider = IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    IReserveFactorV1 public constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);
    IVault public constant balancerBtcPool = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    ILendingPool public constant wbtcLendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    ERC20 public constant awBTC = ERC20(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656);
    ERC20 public constant wBtc = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    bytes32 public constant balancerBtcPoolId = 0xfeadd389a5c427952d8fdb8057d6c8ba1156cc56000000000000000000000066;

    address[] public tokenAddresses = [
        wBtc,
        ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F),
        ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
        ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7),
        ERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200),
        ERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2),
        ERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942),
        ERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53),
        ERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e),
        ERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA),
        ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984),
        ERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)
    ];

    function execute() external {
        // Distribute V1 RF to V2 RF
        addressProvider.setTokenDistributor(reserveFactorV2);
        reserveFactorV1.distribute(tokenAddresses);

        // Approve this contract to move assets on v2's behalf
        uint256 length = tokenAddresses.length;
        for (uint256 i = 0; i < length; i++) {
            collector.approve(tokenAddresses[i], address(this), tokenAddresses[i].balanceOf(reserveFactorV2));
        }

        // Redeem and Deposit wBTC in balancer btc vault
        wbtcLendingPool.withdraw(wBtc, awBTC.balanceOf(reserveFactorV2), reserveFactorV2);
        balancerBtcPool.joinPool(balancerBtcPoolId, reserveFactorV2, reserveFactorV2);
    }
}
