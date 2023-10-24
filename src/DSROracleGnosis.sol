// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { DSROracleBase, IDSROracle } from './DSROracleBase.sol';
import { IDSROracleDataReceiver } from './interfaces/IDSROracleDataReceiver.sol';
import { GnosisReceiver } from 'xchain-helpers/GnosisReceiver.sol';

/**
 * @title  DSROracleGnosis
 * @notice DSR Oracle that sits on Gnosis Chain.
 */
contract DSROracleGnosis is DSROracleBase, GnosisReceiver, IDSROracleDataReceiver {

    constructor(address _l2CrossDomain, uint256 _chainId, address _l1Authority) GnosisReceiver(_l2CrossDomain, _chainId, _l1Authority) {
        // Intentionally left blank
    }

    function setPotData(IDSROracle.PotData calldata data) external onlyCrossChainMessage {
        _setPotData(data);
    }

}
