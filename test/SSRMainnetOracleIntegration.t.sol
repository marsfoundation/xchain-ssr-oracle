// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { DomainHelpers } from "xchain-helpers/testing/Domain.sol";

import { SSRMainnetOracle, IPot } from "../src/SSRMainnetOracle.sol";

interface ISUSDSLike is IPot {
    function drip() external;
    function file(bytes32 what, uint256 data) external;
}

interface IWardsLike {
    function rely(address) external;
}

contract SSRMainnetOracleIntegrationTest is Test {

    using DomainHelpers for *;

    uint256 constant CURR_SSR          = 1e27;
    uint256 constant CURR_CHI          = 1e27;
    uint256 constant CURR_CHI_COMPUTED = 1e27;
    uint256 constant CURR_RHO          = 1725455483;

    uint256 constant ONE_HUNDRED_PCT_APY_SSR = 1.00000002197955315123915302e27;

    address constant PAUSE_PROXY = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    address constant USDS        = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address constant USDS_JOIN   = 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB;
    address constant SUSDS       = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address constant VAT         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    ISUSDSLike       susds;
    SSRMainnetOracle oracle;

    function setUp() public {
        getChain("mainnet").createSelectFork(20692134);  // Sept 6, 2024

        // sUSDS is not active yet (Remove when activated)
        vm.startPrank(PAUSE_PROXY);
        IWardsLike(VAT).rely(SUSDS);
        IWardsLike(USDS).rely(USDS_JOIN);
        vm.stopPrank();

        susds = ISUSDSLike(SUSDS);

        assertEq(susds.ssr(), CURR_SSR);
        assertEq(susds.chi(), CURR_CHI);
        assertEq(susds.rho(), CURR_RHO);

        oracle = new SSRMainnetOracle(SUSDS);
    }

    function test_drip_update() public {
        assertEq(oracle.getSSR(), CURR_SSR);
        assertEq(oracle.getChi(), CURR_CHI);
        assertEq(oracle.getRho(), CURR_RHO);

        susds.drip();

        assertEq(susds.ssr(), CURR_SSR);
        assertEq(susds.chi(), CURR_CHI_COMPUTED);
        assertEq(susds.rho(), block.timestamp);
        
        oracle.refresh();

        assertEq(oracle.getSSR(), CURR_SSR);
        assertEq(oracle.getChi(), CURR_CHI_COMPUTED);
        assertEq(oracle.getRho(), block.timestamp);
    }

    function test_ssr_change() public {
        susds.drip();
        vm.prank(PAUSE_PROXY);
        susds.file("ssr", ONE_HUNDRED_PCT_APY_SSR);

        assertEq(susds.ssr(), ONE_HUNDRED_PCT_APY_SSR);
        assertEq(susds.chi(), CURR_CHI_COMPUTED);
        assertEq(susds.rho(), block.timestamp);
        
        oracle.refresh();

        assertEq(oracle.getSSR(), ONE_HUNDRED_PCT_APY_SSR);
        assertEq(oracle.getChi(), CURR_CHI_COMPUTED);
        assertEq(oracle.getRho(), block.timestamp);

        skip(365 days);
        susds.drip();
        oracle.refresh();

        assertEq(oracle.getSSR(), ONE_HUNDRED_PCT_APY_SSR);
        assertEq(oracle.getChi(), 1.999999999999999999505617035e27);
        assertEq(oracle.getRho(), block.timestamp);
    }

}
