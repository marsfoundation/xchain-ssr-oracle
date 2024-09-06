// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import { ISSROracle } from './ISSROracle.sol';

/**
 * @title  ISSRAuthOracle
 * @notice Consolidated SSR reporting along with some convenience functions.
 */
interface ISSRAuthOracle is ISSROracle {

    /** 
     * @notice Emitted when the maxSSR is updated.
     */
    event SetMaxSSR(uint256 maxSSR);

    /**
     * @notice The data provider role.
     */
    function DATA_PROVIDER_ROLE() external view returns (bytes32);

    /**
     * @notice Get the max ssr.
     */
    function maxSSR() external view returns (uint256);

    /**
     * @notice Set the max ssr.
     * @param  maxSSR The max ssr.
     * @dev    Only callable by the admin role.
     */
    function setMaxSSR(uint256 maxSSR) external;

    /**
     * @notice Update the pot data.
     * @param  data The max ssr.
     * @dev    Only callable by the data provider role.
     */
    function setPotData(ISSROracle.PotData calldata data) external;

}
