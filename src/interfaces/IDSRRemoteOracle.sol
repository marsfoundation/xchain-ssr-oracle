// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IDSROracle } from './IDSROracle.sol';

/**
 * @title  IDSRRemoteOracle
 * @notice A DSR Oracle that sits on a remote chain.
 */
interface IDSRRemoteOracle {

    /**
     * @notice Set the pot data.
     * @dev    This function should only be callable by an authorized relay process.
     * @param  data The data from the pot.
     */
    function setData(IDSROracle.PotData calldata data) external;

}
