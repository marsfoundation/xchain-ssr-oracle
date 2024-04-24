// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { OptimismDomain } from "xchain-helpers/testing/OptimismDomain.sol";

import { DSROracleForwarderOptimism } from "src/forwarders/DSROracleForwarderOptimism.sol";
import { DSROracleReceiverOptimism }  from "src/receivers/DSROracleReceiverOptimism.sol";

import "./DSROracleXChainIntegrationBase.t.sol";

contract DSROracleIntegrationOptimismTest is DSROracleXChainIntegrationBaseTest {

    function setupDomain() internal override {
        remote = new OptimismDomain(getChain('optimism'), mainnet);

        mainnet.selectFork();

        address expectedReceiver = vm.computeCreateAddress(address(this), 5);
        forwarder = new DSROracleForwarderOptimism(address(pot), expectedReceiver);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        DSROracleReceiverOptimism receiver = new DSROracleReceiverOptimism(address(forwarder), oracle);
        
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function test_constructor_forwarder() public {
        DSROracleForwarderOptimism forwarder = new DSROracleForwarderOptimism(address(pot), makeAddr("receiver"));

        assertEq(address(forwarder.pot()), address(pot));
        assertEq(forwarder.l2Oracle(),     makeAddr("receiver"));
    }

    function test_constructor_receiver() public {
        DSROracleReceiverOptimism receiver = new DSROracleReceiverOptimism(address(forwarder), oracle);

        assertEq(address(receiver.oracle()), address(oracle));
        assertEq(receiver.l1Authority(),     address(forwarder));
    }

    function doRefresh() internal override {
        DSROracleForwarderOptimism(address(forwarder)).refresh(500_000);
    }

}
