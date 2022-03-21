// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./interfaces/IReserveFactorV1.sol";
import "./interfaces/IEcosystemReserve.sol";
import "./interfaces/IControllerV2Collector.sol";
import "./interfaces/IAddressesProvider.sol";
import {IVault} from "./interfaces/IVault.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {ILendingPoolConfigurator} from "./interfaces/ILendingPoolConfigurator.sol";
import "forge-std/console.sol";

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

    /// @notice aWBTC token.
    IERC20 private constant aWBTC = IERC20(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656);

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

    /// @notice DPI token address.
    address private constant dpi = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

    /// @notice AAVE V2 LendingPoolConfigurator
    ILendingPoolConfigurator private constant configurator =
        ILendingPoolConfigurator(0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756);

    /// @notice Balancer V2 pool.
    IVault private constant balancerPool = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    /// @notice Stable BTC balancer pool id.
    /// @dev LP token symbol is `staBAL3-BTC`
    bytes32 private constant balancerBtcPoolId = 0xfeadd389a5c427952d8fdb8057d6c8ba1156cc56000000000000000000000066;

    /// @notice AAVE V2 lending pool.
    ILendingPool private constant lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

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

        // enable DPI borrow
        configurator.enableBorrowingOnReserve(dpi, false);
    }

    function distributeTokens() external {
        // Distribute all tokens with meaningful balances to v2
        address[] memory tokenAddresses = new address[](13);
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
        tokenAddresses[11] = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9; // AAVE
        tokenAddresses[12] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH
        reserveFactorV1.distribute(tokenAddresses);
    }

    function joinBalancerPool() external {
        console.log("----- START -----");
        console.log("EXECUTOR WBTC BALANCE: ", IERC20(wBtc).balanceOf(address(this)));
        console.log("ECO RESERVE WBTC BALANCE: ", IERC20(wBtc).balanceOf(address(reserveFactorV2)));
        console.log("EXECUTOR AWBTC BALANCE: ", aWBTC.balanceOf(address(this)));
        console.log("ECO RESERVE AWBTC BALANCE: ", aWBTC.balanceOf(address(reserveFactorV2)));

        // Transfer wBTC and aWBTC to this contract
        collectorController.transfer(IERC20(wBtc), address(this), IERC20(wBtc).balanceOf(address(reserveFactorV2)));
        collectorController.transfer(aWBTC, address(this), aWBTC.balanceOf(address(reserveFactorV2)));

        console.log("----- AFTER TRANSFER -----");
        console.log("EXECUTOR WBTC BALANCE: ", IERC20(wBtc).balanceOf(address(this)));
        console.log("ECO RESERVE WBTC BALANCE: ", IERC20(wBtc).balanceOf(address(reserveFactorV2)));
        console.log("EXECUTOR AWBTC BALANCE: ", aWBTC.balanceOf(address(this)));
        console.log("ECO RESERVE AWBTC BALANCE: ", aWBTC.balanceOf(address(reserveFactorV2)));

        // Redeem aWBTC for wBTC
        uint256 withdrawn = lendingPool.withdraw(address(wBtc), type(uint256).max, address(this));

        console.log("----- AFTER REDEMPTION -----");
        console.log("WITHDRAWN AMOUNT: ", withdrawn);
        console.log("EXECUTOR WBTC BALANCE: ", IERC20(wBtc).balanceOf(address(this)));
        console.log("ECO RESERVE WBTC BALANCE: ", IERC20(wBtc).balanceOf(address(reserveFactorV2)));
        console.log("EXECUTOR AWBTC BALANCE: ", aWBTC.balanceOf(address(this)));
        console.log("ECO RESERVE AWBTC BALANCE: ", aWBTC.balanceOf(address(reserveFactorV2)));

        // Deposit wBTC in balancer btc vault
        address[] memory poolAddresses = new address[](3);
        poolAddresses[0] = wBtc;
        poolAddresses[1] = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
        poolAddresses[2] = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;

        uint256[] memory maxAmountsIn = new uint256[](3);
        maxAmountsIn[0] = IERC20(wBtc).balanceOf(address(this));
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

        IERC20(wBtc).approve(address(balancerPool), IERC20(wBtc).balanceOf(address(this)));
        balancerPool.joinPool(balancerBtcPoolId, address(this), address(reserveFactorV2), request);
    }
}
