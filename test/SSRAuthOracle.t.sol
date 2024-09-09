// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { SSRAuthOracle, ISSROracle } from "../src/SSRAuthOracle.sol";

contract SSRAuthOracleTest is Test {

    event SetMaxSSR(uint256 maxSSR);

    uint256 constant FIVE_PCT_APY_SSR        = 1.000000001547125957863212448e27;
    uint256 constant ONE_HUNDRED_PCT_APY_SSR = 1.00000002197955315123915302e27;
    uint256 constant RAY                     = 1e27;

    SSRAuthOracle oracle;

    function setUp() public {
        // To get some reasonable timestamps that are not 1
        skip(1 * (365 days));

        oracle = new SSRAuthOracle();

        // Feed initial data and set limits
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(this));
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(1e27),
            rho: uint40(block.timestamp)
        }));

        skip(1 * (365 days));
    }

    function test_constructor() public {
        assertEq(oracle.maxSSR(), 0);
    }

    function test_setMaxSSR_notAdmin() public {
        address randomAddress = makeAddr("randomAddress");

        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", randomAddress, oracle.DEFAULT_ADMIN_ROLE()));
        vm.prank(randomAddress);
        oracle.setMaxSSR(ONE_HUNDRED_PCT_APY_SSR);
    }

    function test_setMaxSSR_setToZero() public {
        oracle.setMaxSSR(ONE_HUNDRED_PCT_APY_SSR);

        assertEq(oracle.maxSSR(), ONE_HUNDRED_PCT_APY_SSR);

        vm.expectEmit(address(oracle));
        emit SetMaxSSR(0);
        oracle.setMaxSSR(0);

        assertEq(oracle.maxSSR(), 0);
    }

    function test_setMaxSSR_ray_boundary() public {
        vm.expectRevert("SSRAuthOracle/invalid-max-ssr");
        oracle.setMaxSSR(RAY - 1);

        vm.expectEmit(address(oracle));
        emit SetMaxSSR(RAY);
        oracle.setMaxSSR(RAY);
    }

    function test_setSUSDSData_rho_decreasing_boundary() public {
        uint256 rho = oracle.getRho();
        vm.expectRevert("SSRAuthOracle/invalid-rho");
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(1e27),
            rho: uint40(rho - 1)
        }));

        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(1e27),
            rho: uint40(rho)
        }));
    }

    function test_setSUSDSData_rho_in_future_boundary() public {
        vm.expectRevert("SSRAuthOracle/invalid-rho");
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp + 1)
        }));

        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setSUSDSData_ssr_below_zero_boundary() public {
        vm.expectRevert("SSRAuthOracle/invalid-ssr");
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(1e27 - 1),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));

        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(1e27),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setSUSDSData_ssr_above_max_boundary() public {
        oracle.setMaxSSR(ONE_HUNDRED_PCT_APY_SSR);

        vm.expectRevert("SSRAuthOracle/invalid-ssr");
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(ONE_HUNDRED_PCT_APY_SSR + 1),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));

        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(ONE_HUNDRED_PCT_APY_SSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setSUSDSData_very_high_ssr_no_max() public {
        // Set the SSR to be a very high number (Doubling every second)
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(2e27),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setSUSDSData_chi_decreasing_boundary() public {
        vm.expectRevert("SSRAuthOracle/invalid-chi");
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(1e27 - 1),
            rho: uint40(block.timestamp)
        }));

        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(1e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setSUSDSData_chi_growth_too_fast_boundary() public {
        oracle.setMaxSSR(ONE_HUNDRED_PCT_APY_SSR);

        uint256 chiMax = _rpow(ONE_HUNDRED_PCT_APY_SSR, 365 days);
        assertEq(chiMax, 1.999999999999999999505617035e27);  // Max APY is 100% so ~2x return in 1 year is highest

        vm.expectRevert("SSRAuthOracle/invalid-chi");
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(chiMax + 1),
            rho: uint40(block.timestamp)
        }));

        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(chiMax),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setSUSDSData_chi_large_growth_no_max_ssr() public {
        // A 100,000x return in 1 year is fine with no upper ssr limit
        oracle.setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(FIVE_PCT_APY_SSR),
            chi: uint120(100000e27),
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
