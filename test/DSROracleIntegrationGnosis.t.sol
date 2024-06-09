// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { AMBBridgeTesting } from "xchain-helpers/testing/bridges/AMBBridgeTesting.sol";
import { AMBReceiver }      from "xchain-helpers/receivers/AMBReceiver.sol";

import { DSROracleForwarderGnosis } from "src/forwarders/DSROracleForwarderGnosis.sol";

contract DSROracleIntegrationGnosisTest is DSROracleXChainIntegrationBaseTest {

    using DomainHelpers    for *;
    using AMBBridgeTesting for *;

    function setupDomain() internal override {
        remote = getChain('gnosis_chain').createFork();
        bridge = AMBBridgeTesting.createGnosisBridge(mainnet, remote);

        mainnet.selectFork();

        forwarder = new DSROracleForwarderGnosis(address(pot), vm.computeCreateAddress(address(this), 3));

        remote.selectFork();

        oracle = new DSRAuthOracle();
        AMBReceiver receiver = new AMBReceiver(
            AMBBridgeTesting.getGnosisMessengerFromChainAlias(bridge.destination.chain.chainAlias),
            bytes32(uint256(1)),  // Ethereum chainid
            address(forwarder),
            address(oracle)
        );

        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));
    }

    function test_constructor_forwarder() public {
        DSROracleForwarderGnosis forwarder = new DSROracleForwarderGnosis(address(pot), makeAddr("receiver"));

        assertEq(address(forwarder.pot()), address(pot));
        assertEq(forwarder.l2Oracle(),     makeAddr("receiver"));
    }

    function doRefresh() internal override {
        DSROracleForwarderGnosis(address(forwarder)).refresh(500_000);
    }

    function relayMessagesAcrossBridge() internal override {
        bridge.relayMessagesToDestination(true);
    }

}
