// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { DSRMainnetOracle, IPot } from "../src/DSRMainnetOracle.sol";

interface IPotLike is IPot {
    function drip() external;
    function file(bytes32 what, uint256 data) external;
}

contract DSRMainnetOracleIntegrationTest is Test {

    uint256 constant CURR_DSR          = 1.000000001547125957863212448e27;
    uint256 constant CURR_CHI          = 1.039942074479136064327544607e27;
    uint256 constant CURR_CHI_COMPUTED = 1.039942923989970019616436906e27;
    uint256 constant CURR_RHO          = 1698170603;

    uint256 constant ONE_HUNDRED_PCT_APY_DSR = 1.00000002197955315123915302e27;

    address constant PAUSE_PROXY = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    address constant POT         = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    IPotLike         pot;
    DSRMainnetOracle oracle;

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18421823);

        pot = IPotLike(POT);

        assertEq(pot.dsr(), CURR_DSR);
        assertEq(pot.chi(), CURR_CHI);
        assertEq(pot.rho(), CURR_RHO);

        oracle = new DSRMainnetOracle(POT);
    }

    function test_drip_update() public {
        assertEq(oracle.getDSR(), CURR_DSR);
        assertEq(oracle.getChi(), CURR_CHI);
        assertEq(oracle.getRho(), CURR_RHO);

        pot.drip();

        assertEq(pot.dsr(), CURR_DSR);
        assertEq(pot.chi(), CURR_CHI_COMPUTED);
        assertEq(pot.rho(), block.timestamp);
        
        oracle.refresh();

        assertEq(oracle.getDSR(), CURR_DSR);
        assertEq(oracle.getChi(), CURR_CHI_COMPUTED);
        assertEq(oracle.getRho(), block.timestamp);
    }

    function test_dsr_change() public {
        pot.drip();
        vm.prank(PAUSE_PROXY);
        pot.file("dsr", ONE_HUNDRED_PCT_APY_DSR);

        assertEq(pot.dsr(), ONE_HUNDRED_PCT_APY_DSR);
        assertEq(pot.chi(), CURR_CHI_COMPUTED);
        assertEq(pot.rho(), block.timestamp);
        
        oracle.refresh();

        assertEq(oracle.getDSR(), ONE_HUNDRED_PCT_APY_DSR);
        assertEq(oracle.getChi(), CURR_CHI_COMPUTED);
        assertEq(oracle.getRho(), block.timestamp);

        skip(365 days);
        pot.drip();
        oracle.refresh();

        assertEq(oracle.getDSR(), ONE_HUNDRED_PCT_APY_DSR);
        assertEq(oracle.getChi(), 2.079885847979940038718743745e27);
        assertEq(oracle.getRho(), block.timestamp);
    }

}
