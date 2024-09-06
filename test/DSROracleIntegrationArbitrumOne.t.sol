// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { ArbitrumBridgeTesting } from "xchain-helpers/testing/bridges/ArbitrumBridgeTesting.sol";
import { ArbitrumReceiver }      from "xchain-helpers/receivers/ArbitrumReceiver.sol";

import { DSROracleForwarderArbitrum, ArbitrumForwarder } from "src/forwarders/DSROracleForwarderArbitrum.sol";

contract DSROracleIntegrationArbitrumOneTest is DSROracleXChainIntegrationBaseTest {

    using DomainHelpers         for *;
    using ArbitrumBridgeTesting for *;

    function setupDomain() internal override {
        remote = getChain('arbitrum_one').createFork();
        bridge = ArbitrumBridgeTesting.createNativeBridge(mainnet, remote);

        mainnet.selectFork();

        address expectedReceiver = computeCreateAddress(address(this), 4);
        forwarder = new DSROracleForwarderArbitrum(address(pot), expectedReceiver, ArbitrumForwarder.L1_CROSS_DOMAIN_ARBITRUM_ONE);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        ArbitrumReceiver receiver = new ArbitrumReceiver(address(forwarder), address(oracle));
        
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function test_constructor_forwarder() public {
        DSROracleForwarderArbitrum forwarder = new DSROracleForwarderArbitrum(address(pot), makeAddr("receiver"), ArbitrumForwarder.L1_CROSS_DOMAIN_ARBITRUM_ONE);

        assertEq(address(forwarder.pot()), address(pot));
        assertEq(forwarder.l2Oracle(),     makeAddr("receiver"));
    }

    function doRefresh() internal override {
        DSROracleForwarderArbitrum(address(forwarder)).refresh{value:1 ether}(500_000, 1 gwei, block.basefee + 10 gwei);
    }

    function relayMessagesAcrossBridge() internal override {
        bridge.relayMessagesToDestination(true);
    }

}
