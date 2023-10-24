// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { XChainForwarders } from 'xchain-helpers/XChainForwarders.sol';
import { IDSROracle } from './IDSROracle.sol';
import { IDSRRemoteOracle } from './IDSRRemoteOracle.sol';

interface IPot {
    function dsr() external view returns (uint256);
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
}

/**
 * @title  GnosisDSROracleRelayer
 * @notice Relay DSR data cross-chain via the AMB.
 */
contract GnosisDSROracleRelayer {

    IPot    public immutable pot;
    address public immutable l2Oracle;

    constructor(address _pot, address _l2Oracle) {
        pot = IPot(_pot);
        l2Oracle = _l2Oracle;

        refresh();
    }

    /**
    * @notice Send pot values cross-chain.
    * @dev    This does not need to be called that frequently as the values provide complete precision if needed.
    *         `refresh()` should be called immediately whenever the `dsr` value changes.
    * @param  gasLimit The gas limit for the cross-chain transaction.
    */
    function refresh(uint256 gasLimit) public {
        XChainForwarders.sendMessageGnosis(
            l2Oracle,
            abi.encodeWithSelector(
                IDSRRemoteOracle.setData.selector,
                IDSROracle.PotData({
                    dsr: uint96(pot.dsr()),
                    chi: uint120(pot.chi()),
                    rho: uint40(pot.rho())
                })
            ),
            gasLimit
        );
    }

}
