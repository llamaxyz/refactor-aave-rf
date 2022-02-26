// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {IVault} from "@balancer/vault/contracts/interfaces/IVault.sol";
import {ILendingPool} from "@aave/interfaces/ILendingPool.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import "./interfaces/IAddressesProvider.sol";
import "./interfaces/IReserveFactorV1.sol";

contract Refactor {
    IAddressesProvider public constant addressProvider = IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant reserveFactorV2 = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    IReserveFactorV1 public constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);
    IVault public constant balancerBtcPool = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    bytes32 public constant balancerBtcPoolId = 0xfeadd389a5c427952d8fdb8057d6c8ba1156cc56000000000000000000000066;
    ERC20 public constant wBtc = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address[] public tokenAddresses = [
        0x6B175474E89094C44Da98b954EedeAC495271d0F,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        wBtc
    ];
    ILendingPool public constant wbtcPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    ERC20 public constant awbtc = ERC20(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656);

    function execute() external {
        // Distribute V1 RF to V2 RF
        addressProvider.setTokenDistributor(reserveFactorV2);
        reserveFactorV1.distribute(tokenAddresses);

        // Redeem and Deposit wBTC in balancer btc vault
        wbtcPool.withdraw(wBtc, awbtc.balanceOf(reserveFactorV2), reserveFactorV2);
        balancerBtcPool.joinPool(balancerBtcPoolId, reserveFactorV2, reserveFactorV2);
    }
}
