// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { ArbitrumForwarder } from 'xchain-helpers/forwarders/ArbitrumForwarder.sol';

import { DSROracleForwarderBase } from './DSROracleForwarderBase.sol';

contract DSROracleForwarderArbitrumOne is DSROracleForwarderBase {

    constructor(address _pot, address _l2Oracle) DSROracleForwarderBase(_pot, _l2Oracle) {
        // Intentionally left blank
    }

    function refresh(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 baseFee
    ) public payable {
        ArbitrumForwarder.sendMessageL1toL2(
            ArbitrumForwarder.L1_CROSS_DOMAIN_ARBITRUM_ONE,
            address(l2Oracle),
            _packMessage(),
            gasLimit,
            maxFeePerGas,
            baseFee
        );
    }

}
