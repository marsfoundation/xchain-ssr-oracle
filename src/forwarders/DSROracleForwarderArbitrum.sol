// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { ArbitrumForwarder } from 'xchain-helpers/forwarders/ArbitrumForwarder.sol';

import { DSROracleForwarderBase } from './DSROracleForwarderBase.sol';

contract DSROracleForwarderArbitrum is DSROracleForwarderBase {

    address public immutable l1CrossDomain;

    constructor(address _pot, address _l2Oracle, address _l1CrossDomain) DSROracleForwarderBase(_pot, _l2Oracle) {
        l1CrossDomain = _l1CrossDomain;
    }

    function refresh(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 baseFee
    ) public payable {
        ArbitrumForwarder.sendMessageL1toL2(
            l1CrossDomain,
            address(l2Oracle),
            _packMessage(),
            gasLimit,
            maxFeePerGas,
            baseFee
        );
    }

}
