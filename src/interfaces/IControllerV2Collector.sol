// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IControllerV2Collector {
    function transfer(
        address,
        address,
        uint256
    ) external;
}
