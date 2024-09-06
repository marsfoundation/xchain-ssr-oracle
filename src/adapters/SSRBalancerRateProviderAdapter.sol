// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ISSROracle } from "../interfaces/ISSROracle.sol";

interface IRateProvider {
    function getRate() external view returns (uint256);
}

/**
 * @title  SSRBalancerRateProviderAdapter
 * @notice A thin adapter which uses a binomial approximation to get an up-to-date SSR conversion price.
 */
contract SSRBalancerRateProviderAdapter is IRateProvider {

    ISSROracle public immutable ssrOracle;

    constructor(ISSROracle _ssrOracle) {
        ssrOracle = _ssrOracle;
    }

    /**
     * @return The approximated value of 1e18 sUSDS in terms of USDS.
     */
    function getRate() external view override returns (uint256) {
        return ssrOracle.getConversionRateBinomialApprox() / 1e9;
    }

}
