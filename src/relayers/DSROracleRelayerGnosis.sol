// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { XChainForwarders } from 'xchain-helpers/XChainForwarders.sol';
import { DSROracleRelayerBase, IDSROracleDataReceiver } from './DSROracleRelayerBase.sol';

contract DSROracleRelayerGnosis is DSROracleRelayerBase {

    constructor(address _pot, IDSROracleDataReceiver _l2Oracle) DSROracleRelayerBase(_pot, _l2Oracle) {
        // Intentionally left blank
    }

    function refresh(uint256 gasLimit) public {
        XChainForwarders.sendMessageGnosis(
            address(l2Oracle),
            _packMessage(),
            gasLimit
        );
    }

}
