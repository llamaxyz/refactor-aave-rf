// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./ICollector.sol";

interface IControllerV2Collector {

    function COLLECTOR() external view returns (address);

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
}
