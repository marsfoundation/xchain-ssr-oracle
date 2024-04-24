// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { ArbitrumDomain } from "xchain-helpers/testing/ArbitrumDomain.sol";

import { DSROracleForwarderArbitrumOne } from "src/forwarders/DSROracleForwarderArbitrumOne.sol";
import { DSROracleReceiverArbitrum }     from "src/receivers/DSROracleReceiverArbitrum.sol";

import "./DSROracleXChainIntegrationBase.t.sol";

contract DSROracleIntegrationArbitrumTest is DSROracleXChainIntegrationBaseTest {

    function setupDomain() internal override {
        remote = new ArbitrumDomain(getChain('arbitrum_one'), mainnet);

        mainnet.selectFork();

        address expectedReceiver = computeCreateAddress(address(this), 5);
        forwarder = new DSROracleForwarderArbitrumOne(address(pot), expectedReceiver);

        remote.selectFork();

        oracle = new DSRAuthOracle();
        DSROracleReceiverArbitrum receiver = new DSROracleReceiverArbitrum(address(forwarder), oracle);
        
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));

        assertEq(address(receiver), expectedReceiver);
    }

    function test_constructor() public {
        DSROracleReceiverArbitrum receiver = new DSROracleReceiverArbitrum(address(forwarder), oracle);

        assertEq(address(receiver.oracle()), address(oracle));
        assertEq(receiver.l1Authority(),     address(forwarder));
    }

    function doRefresh() internal override {
        DSROracleForwarderArbitrumOne(address(forwarder)).refresh{value:1 ether}(500_000, 1 gwei, block.basefee + 10 gwei);
    }

}
