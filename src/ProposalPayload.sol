// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import {IVault} from "./interfaces/IVault.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import "./interfaces/IAddressesProvider.sol";
import "./interfaces/IReserveFactorV1.sol";
import "./interfaces/IControllerV2Collector.sol";
import "./interfaces/IERC20.sol";
import "forge-std/console.sol";

/// @title Payload to refactor AAVE Reserve Factor
/// @author Austin Green
/// @notice Provides an execute function for Aave governance to refactor its reserve factor.
contract ProposalPayload {
    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice AAVE's V2 Reserve Factor.
    address private constant reserveFactorV2 = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    /// @notice Provides the logic for the V2 address to set ERC20 approvals.
    /// @notice Approvals only be initiated by AAVE's governance executor.
    IControllerV2Collector private constant collectorController =
        IControllerV2Collector(0x7AB1e5c406F36FE20Ce7eBa528E182903CA8bFC7);

    /// @notice Provides address mapping for AAVE.
    IAddressesProvider private constant addressProvider =
        IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    /// @notice AAVE's V1 Reserve Factor.
    IReserveFactorV1 private constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);

    /// @notice Balancer V2 pool.
    IVault private constant balancerPool = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    /// @notice Stable BTC balancer pool id.
    /// @dev LP token symbol is `staBAL3-BTC`
    bytes32 private constant balancerBtcPoolId = 0xfeadd389a5c427952d8fdb8057d6c8ba1156cc56000000000000000000000066;

    /// @notice Balancer boosted pool id.
    /// @dev LP token symbol is `bb-a-USD`
    bytes32 private constant balancerBoostedPoolId = 0x7b50775383d3d6f0215a8f290f2c9e2eebbeceb20000000000000000000000fe;

    /// @notice AAVE V2 lending pool.
    ILendingPool private constant lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    /// @notice aWBTC token.
    IERC20 private constant aWBTC = IERC20(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656);

    /// @notice aDai token.
    IERC20 private constant aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3);

    /// @notice aUsdc token.
    IERC20 private constant aUsdc = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);

    /// @notice aUsdt token.
    IERC20 private constant aUsdt = IERC20(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811);

    /// @notice wBtc token.
    IERC20 private constant wBtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    /// @notice dai token.
    address private constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /// @notice usdc token.
    address private constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// @notice usdt token.
    address private constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Transfer wBTC and aWBTC to this contract
        collectorController.transfer(wBtc, address(this), wBtc.balanceOf(reserveFactorV2));
        collectorController.transfer(aWBTC, address(this), aWBTC.balanceOf(reserveFactorV2));

        // Redeem aWBTC for wBTC
        lendingPool.withdraw(address(wBtc), aWBTC.balanceOf(address(this)), address(this));

        // Deposit wBTC in balancer btc vault
        address[] memory poolAddresses = new address[](3);
        poolAddresses[0] = address(wBtc);
        poolAddresses[1] = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
        poolAddresses[2] = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;

        uint256[] memory maxAmountsIn = new uint256[](3);
        maxAmountsIn[0] = wBtc.balanceOf(address(this));
        maxAmountsIn[1] = 0;
        maxAmountsIn[2] = 0;

        uint256 JoinKindSingleToken = 2;
        uint256 bptAmountOut = 0;
        uint256 enterTokenIndex = 0;
        bytes memory userDataEncoded = abi.encode(JoinKindSingleToken, bptAmountOut, enterTokenIndex);

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: poolAddresses,
            maxAmountsIn: maxAmountsIn,
            userData: userDataEncoded,
            fromInternalBalance: false
        });
        console.log(msg.sender);
        wBtc.approve(address(balancerPool), wBtc.balanceOf(address(this)));
        balancerPool.joinPool(balancerBtcPoolId, address(this), reserveFactorV2, request);
    }
}
