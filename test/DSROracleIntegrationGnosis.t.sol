// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./DSROracleXChainIntegrationBase.t.sol";

import { GnosisDomain } from "xchain-helpers/testing/GnosisDomain.sol";

import { DSROracleRelayerGnosis } from "../src/relayers/DSROracleRelayerGnosis.sol";
import { DSROracleGnosis } from "../src/DSROracleGnosis.sol";

contract DSROracleIntegrationGnosisTest is DSROracleXChainIntegrationBaseTest {

    DSROracleRelayerGnosis relayer;

    function setupDomain() internal override {
        remote = new GnosisDomain(getChain('gnosis_chain'), mainnet);

        mainnet.selectFork();

        relayer = new DSROracleRelayerGnosis(address(pot), computeCreateAddress(address(this), 4));

        remote.selectFork();

        oracle = new DSROracleGnosis(0x75Df5AF045d91108662D8080fD1FEFAd6aA0bb59, 1, address(relayer));
    }

    function doRefresh() internal override {
        relayer.refresh(500_000);
    }

}
