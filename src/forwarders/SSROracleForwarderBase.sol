// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import { ISSRAuthOracle, ISSROracle } from '../interfaces/ISSRAuthOracle.sol';
import { ISUSDS }                     from '../interfaces/ISUSDS.sol';

/**
 * @title  SSROracleForwarderBase
 * @notice Base contract for relaying sUSDS data messages cross-chain.
 */
abstract contract SSROracleForwarderBase {

    using SafeCast for uint256;

    event LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData susdsData);

    ISUSDS  public immutable susds;
    address public immutable l2Oracle;
    
    ISSROracle.SUSDSData public _lastSeenSUSDSData;

    constructor(address _susds, address _l2Oracle) {
        susds    = ISUSDS(_susds);
        l2Oracle = _l2Oracle;
    }

    function _packMessage() internal returns (bytes memory) {
        ISSROracle.SUSDSData memory susdsData = ISSROracle.SUSDSData({
            ssr: susds.ssr().toUint96(),
            chi: uint256(susds.chi()).toUint120(),
            rho: uint256(susds.rho()).toUint40()
        });
        _lastSeenSUSDSData = susdsData;
        emit LastSeenSUSDSDataUpdated(susdsData);
        return abi.encodeCall(
            ISSRAuthOracle.setSUSDSData,
            (susdsData)
        );
    }

    function getLastSeenSUSDSData() external view returns (ISSROracle.SUSDSData memory) {
        return _lastSeenSUSDSData;
    }

    function getLastSeenSSR() external view returns (uint256) {
        return _lastSeenSUSDSData.ssr;
    }

    function getLastSeenChi() external view returns (uint256) {
        return _lastSeenSUSDSData.chi;
    }

    function getLastSeenRho() external view returns (uint256) {
        return _lastSeenSUSDSData.rho;
    }

}
