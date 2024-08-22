// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { AccessControl } from 'openzeppelin-contracts/contracts/access/AccessControl.sol';

import { DSROracleBase, IDSROracle } from './DSROracleBase.sol';
import { IDSRAuthOracle }            from './interfaces/IDSRAuthOracle.sol';

/**
 * @title  DSRAuthOracle
 * @notice DSR Oracle that allows permissioned setting of the pot data.
 */
contract DSRAuthOracle is AccessControl, DSROracleBase, IDSRAuthOracle {

    uint256 private constant RAY = 1e27;

    bytes32 public constant DATA_PROVIDER_ROLE = keccak256('DATA_PROVIDER_ROLE');

    uint256 public maxDSR;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setMaxDSR(uint256 _maxDSR) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxDSR >= RAY || _maxDSR == 0, 'DSRAuthOracle/invalid-max-dsr');

        maxDSR = _maxDSR;
        emit SetMaxDSR(_maxDSR);
    }

    function setPotData(IDSROracle.PotData calldata nextData) external onlyRole(DATA_PROVIDER_ROLE) {
        IDSROracle.PotData memory previousData = _data;

        // Timestamp must be in the past
        require(nextData.rho <= block.timestamp, 'DSRAuthOracle/invalid-rho');

        // DSR lower bound
        require(nextData.dsr >= RAY, 'DSRAuthOracle/invalid-dsr');

        // Optional DSR upper bound
        uint256 _maxDSR = maxDSR;
        if (_maxDSR != 0) {
            require(nextData.dsr <= _maxDSR, 'DSRAuthOracle/invalid-dsr');
        }

        if (_data.rho == 0) {
            // This is a first update
            // No need to run checks
            _setPotData(nextData);
            return;
        }

        // Perform sanity checks to minimize damage in case of malicious data being proposed

        // Enforce non-decreasing values of rho in case of message reordering
        // The same timestamp is allowed as the other values will only change upon increasing rho
        require(nextData.rho >= previousData.rho, 'DSRAuthOracle/invalid-rho');

        // `chi` must be non-decreasing
        require(nextData.chi >= previousData.chi, 'DSRAuthOracle/invalid-chi');

        // Accumulation cannot be larger than the time elapsed at the max dsr
        if (_maxDSR != 0) {
            uint256 chiMax = _rpow(_maxDSR, nextData.rho - previousData.rho) * previousData.chi / RAY;
            require(nextData.chi <= chiMax, 'DSRAuthOracle/invalid-chi');
        }

        _setPotData(nextData);
    }

}
