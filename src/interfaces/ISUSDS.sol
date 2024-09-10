// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

interface ISUSDS {
    function ssr() external view returns (uint256);
    function chi() external view returns (uint192);
    function rho() external view returns (uint64);
}
