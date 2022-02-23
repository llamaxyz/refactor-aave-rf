// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "./interfaces/IAddressesProvider.sol";
import "./interfaces/IReserveFactorV1.sol";

contract Refactor {
    IAddressesProvider public constant addressProvider =
        IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant reserveFactorV2 =
        0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    IReserveFactorV1 public constant reserveFactorV1 =
        IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);
    address[] public tokenAddresses = [
        0x6B175474E89094C44Da98b954EedeAC495271d0F,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    ];

    function execute() external {
        addressProvider.setTokenDistributor(reserveFactorV2);
        reserveFactorV1.distribute(tokenAddresses);
    }
}
