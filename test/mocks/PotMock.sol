// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PotMock {

    uint256 public dsr;
    uint256 public chi;
    uint256 public rho;

    constructor() {
        dsr = 1e27;
        chi = 1e27;
        rho = block.timestamp;
    }

    function setDSR(uint256 _dsr) external {
        dsr = _dsr;
    }

    function setChi(uint256 _chi) external {
        chi = _chi;
    }

    function setRho(uint256 _rho) external {
        rho = _rho;
    }

}
