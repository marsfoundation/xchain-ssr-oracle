// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IDSROracle } from 'src/interfaces/IDSRAuthOracle.sol';

interface IOracleReceiver {
    function setPotData(IDSROracle.PotData calldata data) external;
}
