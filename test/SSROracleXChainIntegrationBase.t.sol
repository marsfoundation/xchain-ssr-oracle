// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";

import { Bridge }                from "xchain-helpers/testing/Bridge.sol";
import { Domain, DomainHelpers } from "xchain-helpers/testing/Domain.sol";

import { SSRAuthOracle  }                  from "../src/SSRAuthOracle.sol";
import { SSROracleForwarderBase  }         from "../src/forwarders/SSROracleForwarderBase.sol";
import { SSRBalancerRateProviderAdapter  } from "../src/adapters/SSRBalancerRateProviderAdapter.sol";
import { ISSROracle }                      from "../src/interfaces/ISSROracle.sol";
import { ISUSDS }                          from "../src/interfaces/ISUSDS.sol";

interface ISUSDSDripLike {
    function drip() external;
}

abstract contract SSROracleXChainIntegrationBaseTest is Test {

    event LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData susdsData);

    using DomainHelpers for *;

    uint256 constant CURR_SSR = 1e27;
    uint256 constant CURR_CHI = 1e27;
    uint256 constant CURR_RHO = 1725455483;

    Domain mainnet;
    Domain remote;
    Bridge bridge;

    address susds = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;

    SSROracleForwarderBase forwarder;

    SSRAuthOracle oracle;

    // Test various adapters
    SSRBalancerRateProviderAdapter balancerAdapter;

    function setUp() public {
        mainnet = getChain("mainnet").createSelectFork(20692134);  // Sept 6, 2024

        assertEq(ISUSDS(susds).ssr(), CURR_SSR);
        assertEq(ISUSDS(susds).chi(), CURR_CHI);
        assertEq(ISUSDS(susds).rho(), CURR_RHO);

        setupDomain();

        remote.selectFork();

        balancerAdapter = new SSRBalancerRateProviderAdapter(oracle);
    }

    function setupDomain() internal virtual;
    function doRefresh() internal virtual;
    function relayMessagesAcrossBridge() internal virtual;

    function test_xchain_relay() public {
        remote.selectFork();

        assertEq(oracle.getSSR(), 0);
        assertEq(oracle.getChi(), 0);
        assertEq(oracle.getRho(), 0);

        mainnet.selectFork();

        // Anchor the time to the RHO so we can check the hard coded value
        vm.warp(CURR_RHO + 30 days);

        uint256 susdsConversionRate = IERC4626(susds).convertToAssets(1e18);
        assertEq(susdsConversionRate, 1e18);

        ISSROracle.SUSDSData memory data = forwarder.getLastSeenSUSDSData();
        assertEq(data.ssr,                   0);
        assertEq(data.chi,                   0);
        assertEq(data.rho,                   0);
        assertEq(forwarder.getLastSeenSSR(), 0);
        assertEq(forwarder.getLastSeenChi(), 0);
        assertEq(forwarder.getLastSeenRho(), 0);

        vm.expectEmit(address(forwarder));
        emit LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData({
            ssr: uint96(CURR_SSR),
            chi: uint120(CURR_CHI),
            rho: uint40(CURR_RHO)
        }));
        doRefresh();

        data = forwarder.getLastSeenSUSDSData();
        assertEq(data.ssr,                   CURR_SSR);
        assertEq(data.chi,                   CURR_CHI);
        assertEq(data.rho,                   CURR_RHO);
        assertEq(forwarder.getLastSeenSSR(), CURR_SSR);
        assertEq(forwarder.getLastSeenChi(), CURR_CHI);
        assertEq(forwarder.getLastSeenRho(), CURR_RHO);

        relayMessagesAcrossBridge();
        vm.warp(CURR_RHO + 30 days);

        assertEq(oracle.getSSR(), CURR_SSR);
        assertEq(oracle.getChi(), CURR_CHI);
        assertEq(oracle.getRho(), CURR_RHO);

        assertEq(balancerAdapter.getRate(), 1e18);
        assertApproxEqAbs(balancerAdapter.getRate(), susdsConversionRate, 1e10);
    }

}
