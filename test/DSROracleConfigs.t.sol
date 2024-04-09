// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { Base }     from "lib/sparklend-address-registry/src/Base.sol";
import { Ethereum } from "lib/sparklend-address-registry/src/Ethereum.sol";
import { Optimism } from "lib/sparklend-address-registry/src/Optimism.sol";

import { DSRBalancerRateProviderAdapter as BalancerRateProvider } from "src/adapters/DSRBalancerRateProviderAdapter.sol";

import { DSROracleForwarderOptimism } from "src/forwarders/DSROracleForwarderOptimism.sol";
import { IDSROracle }                 from "src/interfaces/IDSROracle.sol";
import { DSROracleReceiverOptimism }  from "src/receivers/DSROracleReceiverOptimism.sol";

import { DSRAuthOracle } from "src/DSRAuthOracle.sol";

contract DSROracleConfigsBase is Test {

    address deployer;

    DSRAuthOracle             authOracleL2;
    DSROracleReceiverOptimism receiverL2;
    BalancerRateProvider      balancerRateProviderL2;

    function _assertAuthOracleRoles(bool checkEvents) internal {
        bytes32 DEFAULT_ADMIN_ROLE = authOracleL2.DEFAULT_ADMIN_ROLE();
        bytes32 DATA_PROVIDER_ROLE = keccak256("DATA_PROVIDER_ROLE");

        assertEq(DEFAULT_ADMIN_ROLE, 0x00);

        assertEq(authOracleL2.hasRole(DEFAULT_ADMIN_ROLE, address(deployer)),   false);
        assertEq(authOracleL2.hasRole(DATA_PROVIDER_ROLE, address(receiverL2)), true);

        // TODO: Remove this boolean once base RPC issue is resolved.
        if (!checkEvents) return;

        // Check events to ensure roles haven't been granted to wrong addresses
        // RoleGranted (index_topic_1 bytes32 role, index_topic_2 address account, index_topic_3 address sender)
        bytes32 roleGrantedTopic = 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d;

        bytes32[] memory topics = new bytes32[](1);
        topics[0] = roleGrantedTopic;
        Vm.EthGetLogs[] memory logs = vm.eth_getLogs(0, block.number, address(authOracleL2), topics);
        assertEq(logs.length, 2);

        address adminRoleAddress = address(uint160(uint256(logs[0].topics[2])));

        assertEq(logs[0].topics[1], DEFAULT_ADMIN_ROLE);
        assertEq(adminRoleAddress,  address(deployer));

        address providerRoleAddress = address(uint160(uint256(logs[1].topics[2])));

        assertEq(logs[1].topics[1],   DATA_PROVIDER_ROLE);
        assertEq(providerRoleAddress, address(receiverL2));
    }

    function _assertRatesInfo(IDSROracle.PotData memory lastSeenData) internal {
        assertEq(_rpow(authOracleL2.maxDSR(), 365 days, 1e27), 10.999999999999999999542281371e27);  // ~1100%

        IDSROracle.PotData memory l2Data = authOracleL2.getPotData();

        assertGt(l2Data.dsr, 0);
        assertGt(l2Data.chi, 0);
        assertGt(l2Data.rho, 0);

        assertEq(l2Data.dsr, lastSeenData.dsr);
        assertEq(l2Data.chi, lastSeenData.chi);
        assertEq(l2Data.rho, lastSeenData.rho);

        assertEq(balancerRateProviderL2.getRate(), authOracleL2.getConversionRateBinomialApprox() / 1e9);
    }

    // Copied from https://github.com/makerdao/dss/blob/fa4f6630afb0624d04a003e920b0d71a00331d98/src/pot.sol#L85
    function _rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

}

contract DSROracleConfigsOptimism is DSROracleConfigsBase {

    function setUp() public {
        authOracleL2           = DSRAuthOracle(Optimism.DSR_AUTH_ORACLE);
        receiverL2             = DSROracleReceiverOptimism(Optimism.DSR_RECEIVER);
        balancerRateProviderL2 = BalancerRateProvider(Optimism.DSR_BALANCER_RATE_PROVIDER);

        deployer = 0xd1236a6A111879d9862f8374BA15344b6B233Fbd;
    }

    function test_optimism_deployment() public {
        DSROracleForwarderOptimism forwarderEthereum = DSROracleForwarderOptimism(Ethereum.DSR_FORWARDER_OPTIMISM);

        vm.createSelectFork(getChain('mainnet').rpcUrl, 19618011);  // April 9, 2024

        assertEq(address(forwarderEthereum.l2Oracle()), address(receiverL2));
        assertEq(address(forwarderEthereum.pot()),      Ethereum.POT);

        IDSROracle.PotData memory lastSeenData = forwarderEthereum.getLastSeenPotData();

        vm.createSelectFork(getChain('optimism').rpcUrl, 118532925);  // April 9, 2024

        assertEq(address(receiverL2.l1Authority()),   address(forwarderEthereum));
        assertEq(address(receiverL2.l2CrossDomain()), address(Optimism.L2_MESSENGER));
        assertEq(address(receiverL2.oracle()),        address(authOracleL2));

        _assertAuthOracleRoles(true);
        _assertRatesInfo(lastSeenData);
    }

}

contract DSROracleConfigsBaseChain is DSROracleConfigsBase {

    function setUp() public {
        authOracleL2           = DSRAuthOracle(Base.DSR_AUTH_ORACLE);
        receiverL2             = DSROracleReceiverOptimism(Base.DSR_RECEIVER);
        balancerRateProviderL2 = BalancerRateProvider(Base.DSR_BALANCER_RATE_PROVIDER);

        deployer = 0xd1236a6A111879d9862f8374BA15344b6B233Fbd;
    }

    function test_base_deployment() public {
        DSROracleForwarderOptimism forwarderEthereum = DSROracleForwarderOptimism(Ethereum.DSR_FORWARDER_BASE);

        vm.createSelectFork(getChain('mainnet').rpcUrl, 19618011);  // April 9, 2024

        assertEq(address(forwarderEthereum.l2Oracle()), address(receiverL2));
        assertEq(address(forwarderEthereum.pot()),      Ethereum.POT);

        IDSROracle.PotData memory lastSeenData = forwarderEthereum.getLastSeenPotData();

        vm.createSelectFork(getChain('base').rpcUrl, 12941086);  // April 9, 2024

        assertEq(address(receiverL2.l1Authority()),   address(forwarderEthereum));
        assertEq(address(receiverL2.l2CrossDomain()), address(Base.L2_MESSENGER));
        assertEq(address(receiverL2.oracle()),        address(authOracleL2));

        _assertAuthOracleRoles(false);
        _assertRatesInfo(lastSeenData);
    }

}
