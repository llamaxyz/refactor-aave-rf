// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import "../interfaces/IReserveFactorV1.sol";
import "../interfaces/IAddressesProvider.sol";
import "ds-test/test.sol";
import "./interfaces/Hevm.sol";
import "../Refactor.sol";

contract RefactorTest is DSTest {
    Refactor myRefactor;
    Hevm constant hevm = Hevm(HEVM_ADDRESS);
    address public constant AAVE_EXECUTOR = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    IReserveFactorV1 public constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);
    address public constant reserveFactorV2 = 0xE3d9988F676457123C5fD01297605efdD0Cba1ae;
    ERC20 public constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 public constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 public constant WBTC = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    ERC20 public constant USDT = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IAddressesProvider public constant addressProvider = IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    function setUp() public {
        myRefactor = new Refactor();
    }

    function testExecute() public {
        // Assert that v1 has balances of DAI, USDC, WBTC and USDT before execute
        uint256 v1DaiBalance = DAI.balanceOf(address(reserveFactorV1));
        assertGt(v1DaiBalance, 0);
        uint256 v1UsdcBalance = USDC.balanceOf(address(reserveFactorV1));
        assertGt(v1UsdcBalance, 0);
        uint256 v1WbtcBalance = WBTC.balanceOf(address(reserveFactorV1));
        assertGt(v1WbtcBalance, 0);
        uint256 v1UsdtBalance = USDT.balanceOf(address(reserveFactorV1));
        assertGt(v1UsdtBalance, 0);

        // Assert that address provider is using v1 RF as token distributor
        address tokenDistributor = addressProvider.getTokenDistributor();
        assertEq(address(reserveFactorV1), tokenDistributor);

        // Execute as aave governance
        hevm.startPrank(AAVE_EXECUTOR);
        hevm.deal(address(0xEE56e2B3D491590B5b31738cC34d5232F378a8D5), 100000000000);
        emit log_address(msg.sender);
        myRefactor.execute();
        hevm.stopPrank();

        // After execution, assert asset balances are 0 in v1
        assertEq(v1DaiBalance, 0);
        assertEq(v1UsdcBalance, 0);
        assertEq(v1WbtcBalance, 0);
        assertEq(v1UsdtBalance, 0);

        // Assert that after execute, address provider is using v2 RF as token distributor
        address updatedTokenDistributor = addressProvider.getTokenDistributor();
        assertEq(address(reserveFactorV2), updatedTokenDistributor);
    }
}
