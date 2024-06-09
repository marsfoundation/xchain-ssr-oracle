// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { OptimismBridgeTesting } from "xchain-helpers/testing/bridges/OptimismBridgeTesting.sol";
import { OptimismReceiver }      from "xchain-helpers/receivers/OptimismReceiver.sol";

import { DSROracleForwarderOptimism } from "src/forwarders/DSROracleForwarderOptimism.sol";

contract DSROracleIntegrationOptimismTest is DSROracleXChainIntegrationBaseTest {

    using DomainHelpers         for *;
    using OptimismBridgeTesting for *;

    function setupDomain() internal override {
        remote = getChain('optimism').createFork();
        bridge = OptimismBridgeTesting.createNativeBridge(mainnet, remote);

        mainnet.selectFork();

        address expectedReceiver = vm.computeCreateAddress(address(this), 3);
        forwarder = new DSROracleForwarderOptimism(address(pot), expectedReceiver);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        OptimismReceiver receiver = new OptimismReceiver(address(forwarder), address(oracle));
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function test_constructor_forwarder() public {
        DSROracleForwarderOptimism forwarder = new DSROracleForwarderOptimism(address(pot), makeAddr("receiver"));

        assertEq(address(forwarder.pot()), address(pot));
        assertEq(forwarder.l2Oracle(),     makeAddr("receiver"));
    }

    function doRefresh() internal override {
        DSROracleForwarderOptimism(address(forwarder)).refresh(500_000);
    }

    function relayMessagesAcrossBridge() internal override {
        bridge.relayMessagesToDestination(true);
    }

}
