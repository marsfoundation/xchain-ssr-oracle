// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { ISSROracle }                     from "../src/interfaces/ISSROracle.sol";
import { SSRBalancerRateProviderAdapter } from "../src/adapters/SSRBalancerRateProviderAdapter.sol";

contract SSROracleMock {

    uint256 public conversionRate;

    constructor(uint256 _conversionRate) {
        conversionRate = _conversionRate;
    }

    function getConversionRateBinomialApprox() external view returns (uint256) {
        return conversionRate;
    }

    function setConversionRate(uint256 _conversionRate) external {
        conversionRate = _conversionRate;
    }
    
}

contract SSRBalancerRateProviderAdapterTest is Test {

    SSROracleMock oracle;

    SSRBalancerRateProviderAdapter adapter;

    function setUp() public {
        oracle  = new SSROracleMock(1e27);
        adapter = new SSRBalancerRateProviderAdapter(ISSROracle(address(oracle)));
    }

    function test_constructor() public {
        adapter = new SSRBalancerRateProviderAdapter(ISSROracle(address(oracle)));
        assertEq(address(adapter.ssrOracle()), address(oracle));
    }

    function test_getRate() public {
        assertEq(adapter.getRate(), 1e18);
        oracle.setConversionRate(1.2e27);
        assertEq(adapter.getRate(), 1.2e18);
    }

}
