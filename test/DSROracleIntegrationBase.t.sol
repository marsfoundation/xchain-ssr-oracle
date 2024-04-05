// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { OptimismDomain } from "xchain-helpers/testing/OptimismDomain.sol";

import { DSROracleForwarderBase } from "../src/forwarders/DSROracleForwarderBase.sol";
import { DSROracleReceiverOptimism }  from "../src/receivers/DSROracleReceiverOptimism.sol";

contract DSROracleIntegrationBaseTest is DSROracleXChainIntegrationBaseTest {

    DSROracleForwarderBase forwarder;
    DSROracleReceiverOptimism receiver;

    function setupDomain() internal override {
        remote = new OptimismDomain(getChain('base'), mainnet);

        mainnet.selectFork();

        address expectedReceiver = vm.computeCreateAddress(address(this), 5);
        forwarder = new DSROracleForwarderBase(address(pot), expectedReceiver);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        receiver = new DSROracleReceiverOptimism(address(forwarder), oracle);
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function doRefresh() internal override {
        forwarder.refresh(500_000);
    }

}
