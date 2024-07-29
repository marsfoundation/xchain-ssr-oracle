// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IDSRAuthOracle, IDSROracle } from '../interfaces/IDSRAuthOracle.sol';
import { IPot }                       from '../interfaces/IPot.sol';

/**
 * @title  DSROracleForwarderBase
 * @notice Base contract for relaying pot data messages cross-chain.
 */
abstract contract DSROracleForwarderBase {

    event LastSeenPotDataRefreshed(IDSROracle.PotData potData);

    IPot               public immutable pot;
    address            public immutable l2Oracle;
    
    IDSROracle.PotData public _lastSeenPotData;

    constructor(address _pot, address _l2Oracle) {
        pot      = IPot(_pot);
        l2Oracle = _l2Oracle;
    }

    function _packMessage() internal returns (bytes memory) {
        IDSROracle.PotData memory potData = IDSROracle.PotData({
            dsr: uint96(pot.dsr()),
            chi: uint120(pot.chi()),
            rho: uint40(pot.rho())
        });
        _lastSeenPotData = potData;
        emit LastSeenPotDataRefreshed(potData);
        return abi.encodeCall(
            IDSRAuthOracle.setPotData,
            (potData)
        );
    }

    function getLastSeenPotData() external view returns (IDSROracle.PotData memory) {
        return _lastSeenPotData;
    }

    function getLastSeenDSR() external view returns (uint256) {
        return _lastSeenPotData.dsr;
    }

    function getLastSeenChi() external view returns (uint256) {
        return _lastSeenPotData.chi;
    }

    function getLastSeenRho() external view returns (uint256) {
        return _lastSeenPotData.rho;
    }

}
