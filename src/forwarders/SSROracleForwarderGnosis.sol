// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { AMBForwarder } from 'xchain-helpers/forwarders/AMBForwarder.sol';

import { SSROracleForwarderBase } from './SSROracleForwarderBase.sol';

contract SSROracleForwarderGnosis is SSROracleForwarderBase {

    constructor(address _susds, address _l2Oracle) SSROracleForwarderBase(_susds, _l2Oracle) {
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
