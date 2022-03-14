// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;


import "./IERC20.sol";

interface ICollector {
    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    function initialize(address reserveController) external;

    function getFundsAdmin() external view returns (address);

    function REVISION() external view returns (uint256);
}