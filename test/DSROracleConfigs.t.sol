// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { Ethereum } from "lib/sparklend-address-registry/src/Ethereum.sol";
import { Optimism } from "lib/sparklend-address-registry/src/Optimism.sol";

import { DSRBalancerRateProviderAdapter as RateProvider } from "src/adapters/DSRBalancerRateProviderAdapter.sol";

import { DSROracleForwarderOptimism } from "src/forwarders/DSROracleForwarderOptimism.sol";
import { IDSROracle }                 from "src/interfaces/IDSROracle.sol";
import { DSROracleReceiverOptimism }  from "src/receivers/DSROracleReceiverOptimism.sol";

import { DSRAuthOracle } from "src/DSRAuthOracle.sol";

import { PotMock } from "test/mocks/PotMock.sol";

contract DSROracleConfigs is Test {

    function test_optimism_deployment() public {
        DSROracleForwarderOptimism forwarderEthereum = DSROracleForwarderOptimism(Ethereum.DSR_FORWARDER_OPTIMISM);

        DSRAuthOracle             authOracleL2           = DSRAuthOracle(Optimism.DSR_AUTH_ORACLE);
        DSROracleReceiverOptimism receiverL2             = DSROracleReceiverOptimism(Optimism.DSR_RECEIVER);
        RateProvider              balancerRateProviderL2 = RateProvider(Optimism.DSR_BALANCER_RATE_PROVIDER);

        address deployer = 0xd1236a6A111879d9862f8374BA15344b6B233Fbd;

        vm.createSelectFork(getChain('mainnet').rpcUrl, 19618011);  // April 9, 2024

        assertEq(address(forwarderEthereum.l2Oracle()), address(receiverL2));
        assertEq(address(forwarderEthereum.pot()),      Ethereum.POT);

        IDSROracle.PotData memory lastSeenData = forwarderEthereum.getLastSeenPotData();

        vm.createSelectFork(getChain('optimism').rpcUrl, 118532925);  // April 9, 2024

        bytes32 DEFAULT_ADMIN_ROLE = authOracleL2.DEFAULT_ADMIN_ROLE();
        bytes32 DATA_PROVIDER_ROLE = keccak256("DATA_PROVIDER_ROLE");

        assertEq(authOracleL2.hasRole(DEFAULT_ADMIN_ROLE, deployer),            false);
        assertEq(authOracleL2.hasRole(DATA_PROVIDER_ROLE, address(receiverL2)), true);

        assertEq(_rpow(authOracleL2.maxDSR(), 365 days, 1e27), 10.999999999999999999542281371e27);  // ~1100%

        IDSROracle.PotData memory l2Data = authOracleL2.getPotData();

        assertGt(l2Data.dsr, 0);
        assertGt(l2Data.chi, 0);
        assertGt(l2Data.rho, 0);

        assertEq(l2Data.dsr, lastSeenData.dsr);
        assertEq(l2Data.chi, lastSeenData.chi);
        assertEq(l2Data.rho, lastSeenData.rho);

        assertEq(address(receiverL2.l1Authority()),   address(forwarderEthereum));
        assertEq(address(receiverL2.l2CrossDomain()), address(Optimism.L2_MESSENGER));
        assertEq(address(receiverL2.oracle()),        address(authOracleL2));

        assertEq(balancerRateProviderL2.getRate(), authOracleL2.getConversionRateBinomialApprox() / 1e9);
    }

    function _rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
          switch x case 0 {switch n case 0 {z := b} default {z := 0}}
          default {
            switch mod(n, 2) case 0 { z := b } default { z := x }
            let half := div(b, 2)  // for rounding.
            for { n := div(n, 2) } n { n := div(n,2) } {
              let xx := mul(x, x)
              if iszero(eq(div(xx, x), x)) { revert(0,0) }
              let xxRound := add(xx, half)
              if lt(xxRound, xx) { revert(0,0) }
              x := div(xxRound, b)
              if mod(n,2) {
                let zx := mul(z, x)
                if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                let zxRound := add(zx, half)
                if lt(zxRound, zx) { revert(0,0) }
                z := div(zxRound, b)
              }
            }
          }
        }
      }
}
