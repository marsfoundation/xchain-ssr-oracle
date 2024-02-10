// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { OptimismReceiver } from 'xchain-helpers/OptimismReceiver.sol';

import { IDSRAuthOracle, IDSROracle } from '../interfaces/IDSRAuthOracle.sol';

contract DSROracleReceiverOptimism is OptimismReceiver {

    IDSRAuthOracle public oracle;

    constructor(
        address _l1Authority,
        IDSRAuthOracle _oracle
    ) OptimismReceiver(_l1Authority) {
        oracle = _oracle;
    }

    function setPotData(IDSROracle.PotData calldata data) external onlyCrossChainMessage {
        oracle.setPotData(data);
    }

}
