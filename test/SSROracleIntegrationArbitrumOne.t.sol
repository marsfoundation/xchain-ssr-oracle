// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SSROracleXChainIntegrationBase.t.sol";

import { ArbitrumBridgeTesting } from "xchain-helpers/testing/bridges/ArbitrumBridgeTesting.sol";
import { ArbitrumReceiver }      from "xchain-helpers/receivers/ArbitrumReceiver.sol";

import { SSROracleForwarderArbitrum, ArbitrumForwarder } from "src/forwarders/SSROracleForwarderArbitrum.sol";

contract SSROracleIntegrationArbitrumOneTest is SSROracleXChainIntegrationBaseTest {

    using DomainHelpers         for *;
    using ArbitrumBridgeTesting for *;

    function setupDomain() internal override {
        remote = getChain('arbitrum_one').createFork();
        bridge = ArbitrumBridgeTesting.createNativeBridge(mainnet, remote);

        mainnet.selectFork();

        address expectedReceiver = computeCreateAddress(address(this), 4);
        forwarder = new SSROracleForwarderArbitrum(address(susds), expectedReceiver, ArbitrumForwarder.L1_CROSS_DOMAIN_ARBITRUM_ONE);

        remote.selectFork();

        oracle = new SSRAuthOracle();
        ArbitrumReceiver receiver = new ArbitrumReceiver(address(forwarder), address(oracle));
        
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function test_constructor_forwarder() public {
        SSROracleForwarderArbitrum forwarder = new SSROracleForwarderArbitrum(address(susds), makeAddr("receiver"), ArbitrumForwarder.L1_CROSS_DOMAIN_ARBITRUM_ONE);

        assertEq(address(forwarder.susds()), address(susds));
        assertEq(forwarder.l2Oracle(),       makeAddr("receiver"));
    }

    function doRefresh() internal override {
        SSROracleForwarderArbitrum(address(forwarder)).refresh{value:1 ether}(500_000, 1 gwei, block.basefee + 10 gwei);
    }

    function relayMessagesAcrossBridge() internal override {
        bridge.relayMessagesToDestination(true);
    }

}
