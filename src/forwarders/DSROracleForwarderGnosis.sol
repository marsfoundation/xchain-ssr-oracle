// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { AMBForwarder } from 'xchain-helpers/forwarders/AMBForwarder.sol';

import { DSROracleForwarderBase } from './DSROracleForwarderBase.sol';

contract DSROracleForwarderGnosis is DSROracleForwarderBase {

    constructor(address _pot, address _l2Oracle) DSROracleForwarderBase(_pot, _l2Oracle) {
        // Intentionally left blank
    }

    function refresh(uint256 gasLimit) public {
        AMBForwarder.sendMessageEthereumToGnosisChain(
            address(l2Oracle),
            _packMessage(),
            gasLimit
        );
    }

}
