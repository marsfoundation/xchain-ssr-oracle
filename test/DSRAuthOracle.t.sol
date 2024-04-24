// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { DSRAuthOracle, IDSROracle } from "../src/DSRAuthOracle.sol";

contract DSRAuthOracleTest is Test {

    event SetPotData(IDSROracle.PotData nextData);

    uint256 constant FIVE_PCT_APY_DSR        = 1.000000001547125957863212448e27;
    uint256 constant ONE_HUNDRED_PCT_APY_DSR = 1.00000002197955315123915302e27;
    uint256 constant RAY                     = 1e27;

    DSRAuthOracle oracle;

    function setUp() public {
        // To get some reasonable timestamps that are not 1
        skip(1 * (365 days));

        oracle = new DSRAuthOracle();

        // Feed initial data and set limits
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(this));
        oracle.setMaxDSR(ONE_HUNDRED_PCT_APY_DSR);
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1e27),
            rho: uint40(block.timestamp)
        }));

        skip(1 * (365 days));
    }

    function test_setMaxDSR_boundary() public {
        vm.expectRevert("DSRAuthOracle/invalid-max-dsr");
        oracle.setMaxDSR(RAY - 1);

        oracle.setMaxDSR(RAY);
    }

    function test_setPotData_rho_decreasing_boundary() public {
        uint256 rho = oracle.getRho();
        vm.expectRevert("DSRAuthOracle/invalid-rho");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1e27),
            rho: uint40(rho - 1)
        }));

        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1e27),
            rho: uint40(rho)
        }));
    }

    function test_setPotData_rho_in_future_boundary() public {
        vm.expectRevert("DSRAuthOracle/invalid-rho");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp + 1)
        }));

        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setPotData_dsr_below_zero_boundary() public {
        vm.expectRevert("DSRAuthOracle/invalid-dsr");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(1e27 - 1),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));

        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(1e27),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setPotData_dsr_above_100pct_boundary() public {
        vm.expectRevert("DSRAuthOracle/invalid-dsr");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(ONE_HUNDRED_PCT_APY_DSR + 1),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));

        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(ONE_HUNDRED_PCT_APY_DSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setPotData_chi_decreasing_boundary() public {
        vm.expectRevert("DSRAuthOracle/invalid-chi");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1e27 - 1),
            rho: uint40(block.timestamp)
        }));

        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setPotData_chi_growth_too_fast_boundary() public {
        uint256 chiMax = _rpow(ONE_HUNDRED_PCT_APY_DSR, 365 days);
        assertEq(chiMax, 1.999999999999999999505617035e27);  // Max APY is 100% so ~2x return in 1 year is highest

        vm.expectRevert("DSRAuthOracle/invalid-chi");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(chiMax + 1),
            rho: uint40(block.timestamp)
        }));

        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(chiMax),
            rho: uint40(block.timestamp)
        }));
    }

    function _rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := RAY} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := RAY } default { z := x }
                let half := div(RAY, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, RAY)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, RAY)
                    }
                }
            }
        }
    }

}
