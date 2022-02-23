// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

interface IAddressesProvider {
    function setTokenDistributor(address) external;
    function getTokenDistributor() external view returns (address);
    function owner() external view returns (address);
}
