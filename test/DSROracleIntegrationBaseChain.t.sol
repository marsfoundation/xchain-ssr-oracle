// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { OptimismBridgeTesting } from "xchain-helpers/testing/bridges/OptimismBridgeTesting.sol";
import { OptimismReceiver }      from "xchain-helpers/receivers/OptimismReceiver.sol";

import { DSROracleForwarderBaseChain } from "src/forwarders/DSROracleForwarderBaseChain.sol";

contract DSROracleIntegrationBaseChainTest is DSROracleXChainIntegrationBaseTest {

    using DomainHelpers         for *;
    using OptimismBridgeTesting for *;

    function setupDomain() internal override {
        remote = getChain('base').createFork();
        bridge = OptimismBridgeTesting.createNativeBridge(mainnet, remote);

        mainnet.selectFork();

        address expectedReceiver = vm.computeCreateAddress(address(this), 3);
        forwarder = new DSROracleForwarderBaseChain(address(pot), expectedReceiver);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        OptimismReceiver receiver = new OptimismReceiver(address(forwarder), address(oracle));
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function test_constructor_forwarder() public {
        DSROracleForwarderBaseChain forwarder = new DSROracleForwarderBaseChain(address(pot), makeAddr("receiver"));

        assertEq(address(forwarder.pot()), address(pot));
        assertEq(forwarder.l2Oracle(),     makeAddr("receiver"));
    }

    function doRefresh() internal override {
        DSROracleForwarderBaseChain(address(forwarder)).refresh(500_000);
    }

    function relayMessagesAcrossBridge() internal override {
        bridge.relayMessagesToDestination(true);
    }

}
