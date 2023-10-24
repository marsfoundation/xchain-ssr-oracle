// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { BridgedDomain, Domain } from "xchain-helpers/testing/BridgedDomain.sol";

import { DSROracle, IPot } from "../src/DSROracle.sol";

import { GnosisDomain } from "xchain-helpers/testing/GnosisDomain.sol";
import { DSROracleRelayerGnosis } from "../src/relayers/DSROracleRelayerGnosis.sol";
import { DSROracleGnosis } from "../src/DSROracleGnosis.sol";

interface IPotDripLike {
    function drip() external;
}

contract DSROracleIntegrationTest is Test {

    Domain mainnet;
    BridgedDomain gnosis;

    address pot;

    DSROracle oracle;

    DSROracleRelayerGnosis gnosisRelayer;
    DSROracleGnosis gnosisOracle;

    function setUp() public {
        mainnet = new Domain(getChain("mainnet"));
        mainnet.rollFork(18_421_823);
        gnosis = new GnosisDomain(getChain('gnosis_chain'), mainnet);
        
        pot = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

        mainnet.selectFork();

        assertEq(IPot(pot).dsr(), 1.000000001547125957863212448e27);
        assertEq(IPot(pot).chi(), 1.039942074479136064327544607e27);
        assertEq(IPot(pot).rho(), 1698170603);

        oracle = new DSROracle(address(pot));

        gnosisRelayer = new DSROracleRelayerGnosis(address(pot), computeCreateAddress(address(this), 5));

        gnosis.selectFork();

        gnosisOracle = new DSROracleGnosis(0x75Df5AF045d91108662D8080fD1FEFAd6aA0bb59, 1, address(gnosisRelayer));
    }

    function test_mainnet() public {
        mainnet.selectFork();

        assertEq(oracle.getDSR(), 1.000000001547125957863212448e27);
        assertEq(oracle.getChi(), 1.039942074479136064327544607e27);
        assertEq(oracle.getRho(), 1698170603);

        IPotDripLike(pot).drip();

        assertEq(IPot(pot).dsr(), 1.000000001547125957863212448e27);
        assertGt(IPot(pot).chi(), 1.039942074479136064327544607e27);
        assertEq(IPot(pot).rho(), block.timestamp);
        
        oracle.refresh();

        assertEq(oracle.getDSR(), 1.000000001547125957863212448e27);
        assertEq(oracle.getChi(), IPot(pot).chi());
        assertEq(oracle.getRho(), block.timestamp);
    }

    function test_gnosis() public {
        gnosis.selectFork();

        assertEq(gnosisOracle.getDSR(), 0);
        assertEq(gnosisOracle.getChi(), 0);
        assertEq(gnosisOracle.getRho(), 0);

        mainnet.selectFork();

        gnosisRelayer.refresh(500_000);

        gnosis.relayFromHost(true);

        assertEq(gnosisOracle.getDSR(), 1.000000001547125957863212448e27);
        assertEq(gnosisOracle.getChi(), 1.039942074479136064327544607e27);
        assertEq(gnosisOracle.getRho(), 1698170603);
    }

}
