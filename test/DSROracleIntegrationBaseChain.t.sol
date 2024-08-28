// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { OptimismBridgeTesting } from "xchain-helpers/testing/bridges/OptimismBridgeTesting.sol";
import { OptimismReceiver }      from "xchain-helpers/receivers/OptimismReceiver.sol";

import { DSROracleForwarderOptimism, OptimismForwarder } from "src/forwarders/DSROracleForwarderOptimism.sol";

contract DSROracleIntegrationBaseChainTest is DSROracleXChainIntegrationBaseTest {

    using DomainHelpers         for *;
    using OptimismBridgeTesting for *;

    function setupDomain() internal override {
        remote = getChain('base').createFork();
        bridge = OptimismBridgeTesting.createNativeBridge(mainnet, remote);

        mainnet.selectFork();

        address expectedReceiver = vm.computeCreateAddress(address(this), 3);
        forwarder = new DSROracleForwarderOptimism(address(pot), expectedReceiver, OptimismForwarder.L1_CROSS_DOMAIN_BASE);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        OptimismReceiver receiver = new OptimismReceiver(address(forwarder), address(oracle));
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function doRefresh() internal override {
        DSROracleForwarderOptimism(address(forwarder)).refresh(500_000);
    }

    function relayMessagesAcrossBridge() internal override {
        bridge.relayMessagesToDestination(true);
    }

}
