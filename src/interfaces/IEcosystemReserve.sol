// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IEcosystemReserve {
    function upgradeToAndCall(address, bytes calldata) external payable;
}