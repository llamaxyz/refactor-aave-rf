// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}

interface IControllerV2Collector {
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

    function owner() external view returns (address);

    function getFundsAdmin() external view returns (address);

    function REVISION() external view returns (uint256);
}
