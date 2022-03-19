// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

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