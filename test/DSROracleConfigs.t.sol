// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { Ethereum } from "lib/sparklend-address-registry/src/Ethereum.sol";
import { Optimism } from "lib/sparklend-address-registry/src/Optimism.sol";

import { PotMock } from "./mocks/PotMock.sol";

import { DSROracleForwarderOptimism } from "../src/forwarders/DSROracleForwarderOptimism.sol";

contract DSROracleConfigs is Test {

//     Forwarder (Ethereum): [0x4042127DecC0cF7cc0966791abebf7F76294DeF3](https://etherscan.io/address/0x4042127DecC0cF7cc0966791abebf7F76294DeF3#code)
// AuthOracle (Optimism): [0x33a3aB524A43E69f30bFd9Ae97d1Ec679FF00B64](https://optimistic.etherscan.io/address/0x33a3ab524a43e69f30bfd9ae97d1ec679ff00b64#code)
// Receiver (Optimism): [0xE206AEbca7B28e3E8d6787df00B010D4a77c32F3](https://optimistic.etherscan.io/address/0xE206AEbca7B28e3E8d6787df00B010D4a77c32F3#code)
// Balancer Rate Provider (Optimism): [0x15ACEE5F73b36762Ab1a6b7C98787b8148447898](https://optimistic.etherscan.io/address/0x15ACEE5F73b36762Ab1a6b7C98787b8148447898#code)

    function test_optimism_deployment() public {
        DSROracleForwarderOptimism forwarderEthereum = DSROracleForwarderOptimism(Ethereum.DSR_FORWARDER_OPTIMISM);

        address authOracleL2           = 0x33a3aB524A43E69f30bFd9Ae97d1Ec679FF00B64;
        address receiverL2             = 0xE206AEbca7B28e3E8d6787df00B010D4a77c32F3;
        address balancerRateProviderL2 = 0x15ACEE5F73b36762Ab1a6b7C98787b8148447898;

        vm.createSelectFork(getChain('mainnet').rpcUrl, 19618011);  // April 9, 2024

        assertEq(forwarderEthereum.l2Oracle(),     receiverL2);
        assertEq(address(forwarderEthereum.pot()), Ethereum.POT);

        vm.createSelectFork(getChain('optimism').rpcUrl, 118532925);  // April 9, 2024

    }
}
