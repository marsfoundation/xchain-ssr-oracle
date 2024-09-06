// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { AccessControl } from 'openzeppelin-contracts/contracts/access/AccessControl.sol';

import { SSROracleBase, ISSROracle } from './SSROracleBase.sol';
import { ISSRAuthOracle }            from './interfaces/ISSRAuthOracle.sol';

/**
 * @title  SSRAuthOracle
 * @notice SSR Oracle that allows permissioned setting of the pot data.
 */
contract SSRAuthOracle is AccessControl, SSROracleBase, ISSRAuthOracle {

    uint256 private constant RAY = 1e27;

    bytes32 public constant DATA_PROVIDER_ROLE = keccak256('DATA_PROVIDER_ROLE');

    uint256 public maxSSR;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setMaxSSR(uint256 _maxSSR) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxSSR >= RAY || _maxSSR == 0, 'SSRAuthOracle/invalid-max-ssr');

        maxSSR = _maxSSR;
        emit SetMaxSSR(_maxSSR);
    }

    function setPotData(ISSROracle.PotData calldata nextData) external onlyRole(DATA_PROVIDER_ROLE) {
        ISSROracle.PotData memory previousData = _data;

        // Timestamp must be in the past
        require(nextData.rho <= block.timestamp, 'SSRAuthOracle/invalid-rho');

        // SSR lower bound
        require(nextData.ssr >= RAY, 'SSRAuthOracle/invalid-ssr');

        // Optional SSR upper bound
        uint256 _maxSSR = maxSSR;
        if (_maxSSR != 0) {
            require(nextData.ssr <= _maxSSR, 'SSRAuthOracle/invalid-ssr');
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
        require(nextData.rho >= previousData.rho, 'SSRAuthOracle/invalid-rho');

        // `chi` must be non-decreasing
        require(nextData.chi >= previousData.chi, 'SSRAuthOracle/invalid-chi');

        // Accumulation cannot be larger than the time elapsed at the max ssr
        if (_maxSSR != 0) {
            uint256 chiMax = _rpow(_maxSSR, nextData.rho - previousData.rho) * previousData.chi / RAY;
            require(nextData.chi <= chiMax, 'SSRAuthOracle/invalid-chi');
        }

        _setPotData(nextData);
    }

}
