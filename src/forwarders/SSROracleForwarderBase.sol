// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import { ISSRAuthOracle, ISSROracle } from '../interfaces/ISSRAuthOracle.sol';
import { IPot }                       from '../interfaces/IPot.sol';

/**
 * @title  SSROracleForwarderBase
 * @notice Base contract for relaying pot data messages cross-chain.
 */
abstract contract SSROracleForwarderBase {

    using SafeCast for uint256;

    event LastSeenPotDataUpdated(ISSROracle.PotData potData);

    IPot               public immutable pot;
    address            public immutable l2Oracle;
    
    ISSROracle.PotData public _lastSeenPotData;

    constructor(address _pot, address _l2Oracle) {
        pot      = IPot(_pot);
        l2Oracle = _l2Oracle;
    }

    function _packMessage() internal returns (bytes memory) {
        ISSROracle.PotData memory potData = ISSROracle.PotData({
            ssr: pot.ssr().toUint96(),
            chi: pot.chi().toUint120(),
            rho: pot.rho().toUint40()
        });
        _lastSeenPotData = potData;
        emit LastSeenPotDataUpdated(potData);
        return abi.encodeCall(
            ISSRAuthOracle.setPotData,
            (potData)
        );
    }

    function getLastSeenPotData() external view returns (ISSROracle.PotData memory) {
        return _lastSeenPotData;
    }

    function getLastSeenSSR() external view returns (uint256) {
        return _lastSeenPotData.ssr;
    }

    function getLastSeenChi() external view returns (uint256) {
        return _lastSeenPotData.chi;
    }

    function getLastSeenRho() external view returns (uint256) {
        return _lastSeenPotData.rho;
    }

}
