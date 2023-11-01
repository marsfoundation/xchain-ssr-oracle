// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PotMock } from "./mocks/PotMock.sol";

import { DSROracle } from "../src/DSROracle.sol";

contract DSROracleTest is Test {

    uint256 constant FIVE_PCT_APY_DSR = 1.000000001547125957863212448e27;
    uint256 constant FIVE_PCT_APY_APR = 0.048790164207174267760128000e27;

    PotMock   pot;
    DSROracle oracle;

    function setUp() public {
        skip(30 * (365 days));  // Skip 30 years to avoid underflow

        pot = new PotMock();
        oracle = new DSROracle(address(pot));
    }

    function test_storage_defaults() public {
        assertEq(oracle.getDSR(), 1e27);
        assertEq(oracle.getChi(), 1e27);
        assertEq(oracle.getRho(), block.timestamp);
    }

    function test_apr() public {
        assertEq(oracle.getAPR(), 0);

        pot.setDSR(FIVE_PCT_APY_DSR);

        assertEq(oracle.getAPR(), 0);

        oracle.refresh();

        assertEq(oracle.getAPR(), FIVE_PCT_APY_APR);
    }

    function test_getConversionRate() public {
        assertEq(oracle.getConversionRate(), 1e27);
        assertEq(oracle.getConversionRate(block.timestamp + 365 days), 1e27);

        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();

        assertEq(oracle.getConversionRate(), 1.03e27);
        assertEq(oracle.getConversionRate(block.timestamp + 365 days), 1.081499999999999999959902249e27);   // 5% interest on 1.03 value = 1.0815
    }

    function test_gas_getConversionRate_1hour() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRate(block.timestamp + 1 hours);
    }

    function test_gas_getConversionRate_1year() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRate(block.timestamp + 365 days);
    }

    function test_getConversionRate_pastRevert() public {
        vm.expectRevert("DSROracleBase/invalid-timestamp");
        oracle.getConversionRate(block.timestamp - 1);

        oracle.getConversionRate(block.timestamp);
    }

    function test_getConversionRateBinomialApprox() public {
        assertEq(oracle.getConversionRateBinomialApprox(), 1e27);
        assertEq(oracle.getConversionRateBinomialApprox(block.timestamp + 365 days), 1e27);

        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();

        assertEq(oracle.getConversionRateBinomialApprox(), 1.03e27);
        assertEq(oracle.getConversionRateBinomialApprox(block.timestamp + 365 days), 1.081495968383924399665215760e27);   // 5% interest on 1.03 value = 1.0815
    }

    function test_gas_getConversionRateBinomialApprox_1hour() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateBinomialApprox(block.timestamp + 1 hours);
    }

    function test_gas_getConversionRateBinomialApprox_1year() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateBinomialApprox(block.timestamp + 365 days);
    }

    function test_getConversionRateBinomialApprox_pastRevert() public {
        vm.expectRevert("DSROracleBase/invalid-timestamp");
        oracle.getConversionRateBinomialApprox(block.timestamp - 1);

        oracle.getConversionRateBinomialApprox(block.timestamp);
    }

    function test_getConversionRateLinearApprox() public {
        assertEq(oracle.getConversionRateLinearApprox(), 1e27);
        assertEq(oracle.getConversionRateLinearApprox(block.timestamp + 365 days), 1e27);

        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();

        assertEq(oracle.getConversionRateLinearApprox(), 1.03e27);
        assertEq(oracle.getConversionRateLinearApprox(block.timestamp + 365 days), 1.080253869133389495792931840e27);   // 5% interest on 1.03 value = 1.0815, but linear approx is 1.0802
    }

    function test_gas_getConversionRateLinearApprox_1hour() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateLinearApprox(block.timestamp + 1 hours);
    }

    function test_gas_getConversionRateLinearApprox_1year() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateLinearApprox(block.timestamp + 365 days);
    }

    function test_getConversionRateLinearApprox_pastRevert() public {
        vm.expectRevert("DSROracleBase/invalid-timestamp");
        oracle.getConversionRateLinearApprox(block.timestamp - 1);

        oracle.getConversionRateLinearApprox(block.timestamp);
    }

    function test_binomialAccuracyLongDuration() public {
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        oracle.refresh();

        // Even after a year the binomial is accurate to within 0.001%
        assertApproxEqRel(
            oracle.getConversionRate(block.timestamp + 365 days),
            oracle.getConversionRateBinomialApprox(block.timestamp + 365 days),
            0.00001e18
        );
    }

    function test_getConversionRateFuzz(uint256 rate, uint256 duration) public {
        rate     = bound(rate,     0, 1e27);    // Bound by 0-100% APR
        duration = bound(duration, 0, 1 days);  // Bound by 1 day

        pot.setDSR(rate / 365 days + 1e27);
        oracle.refresh();

        skip(duration);

        uint256 exact = oracle.getConversionRate();
        uint256 binomial = oracle.getConversionRateBinomialApprox();
        uint256 linear = oracle.getConversionRateLinearApprox();

        // Error bounds
        assertApproxEqRel(exact, binomial, 0.00000000001e18, "binomial out of range");
        assertApproxEqRel(exact, linear,   0.00005e18,       "linear out of range");

        // Binomial and then linear should always underestimate
        assertGe(exact, binomial);
        assertGe(binomial, linear);
    }

}
