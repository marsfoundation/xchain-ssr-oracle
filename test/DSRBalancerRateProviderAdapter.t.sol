// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IDSROracle }                     from "../src/interfaces/IDSROracle.sol";
import { DSRBalancerRateProviderAdapter } from "../src/adapters/DSRBalancerRateProviderAdapter.sol";

contract DSROracleMock {

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

contract DSRBalancerRateProviderAdapterTest is Test {

    DSROracleMock oracle;

    DSRBalancerRateProviderAdapter adapter;

    function setUp() public {
        oracle  = new DSROracleMock(1e27);
        adapter = new DSRBalancerRateProviderAdapter(IDSROracle(address(oracle)));
    }

    function test_constructor() public {
        adapter = new DSRBalancerRateProviderAdapter(IDSROracle(address(oracle)));
        assertEq(address(adapter.dsrOracle()), address(oracle));
    }

    function test_getRate() public {
        assertEq(adapter.getRate(), 1e18);
        oracle.setConversionRate(1.2e27);
        assertEq(adapter.getRate(), 1.2e18);
    }

}
