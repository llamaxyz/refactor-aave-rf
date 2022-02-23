// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

interface IReserveFactorV1 {
    function distribute(address[] memory) external;
}
