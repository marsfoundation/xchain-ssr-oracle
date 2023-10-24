// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IDSROracle, IDSROracleDataReceiver } from '../interfaces/IDSROracleDataReceiver.sol';
import { IPot } from '../interfaces/IPot.sol';

/**
 * @title  DSROracleRelayerBase
 * @notice Base contract for relaying pot data messages cross-chain.
 */
abstract contract DSROracleRelayerBase {

    IPot                   public immutable pot;
    IDSROracleDataReceiver public immutable l2Oracle;

    constructor(address _pot, IDSROracleDataReceiver _l2Oracle) {
        pot = IPot(_pot);
        l2Oracle = _l2Oracle;
    }

    function _packMessage() internal view returns (bytes memory) {
        return abi.encodeWithSelector(
            IDSROracleDataReceiver.setPotData.selector,
            IDSROracle.PotData({
                dsr: uint96(pot.dsr()),
                chi: uint120(pot.chi()),
                rho: uint40(pot.rho())
            })
        );
    }

}
