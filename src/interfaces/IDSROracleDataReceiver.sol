// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IDSROracle } from './IDSROracle.sol';

/**
 * @title  IDSROracleDataReceiver
 * @notice A receiver of pot data.
 */
interface IDSROracleDataReceiver {

    /**
     * @notice Set the pot data.
     * @dev    This function should only be callable by an authorized party.
     * @param  data The data from the pot.
     */
    function setPotData(IDSROracle.PotData calldata data) external;

}
