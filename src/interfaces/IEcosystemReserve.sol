// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IEcosystemReserve {
    function upgradeTo(address) external;

    function upgradeToAndCall(address, bytes calldata) external payable;

    function transfer(
        address,
        address,
        uint256
    ) external;
}
