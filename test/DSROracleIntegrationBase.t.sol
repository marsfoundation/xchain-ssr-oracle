// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { OptimismDomain } from "xchain-helpers/testing/OptimismDomain.sol";

import { DSROracleForwarderBaseChain } from "../src/forwarders/DSROracleForwarderBaseChain.sol";
import { DSROracleReceiverOptimism }  from "../src/receivers/DSROracleReceiverOptimism.sol";

contract DSROracleIntegrationBaseTest is DSROracleXChainIntegrationBaseTest {

    function setupDomain() internal override {
        remote = new OptimismDomain(getChain('base'), mainnet);

        mainnet.selectFork();

        address expectedReceiver = vm.computeCreateAddress(address(this), 5);
        forwarder = new DSROracleForwarderBaseChain(address(pot), expectedReceiver);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        DSROracleReceiverOptimism receiver = new DSROracleReceiverOptimism(address(forwarder), oracle);
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function doRefresh() internal override {
        DSROracleForwarderBaseChain(address(forwarder)).refresh(500_000);
    }

}
