// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { OptionsBuilder } from "layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import { Bridge }                from "xchain-helpers/testing/Bridge.sol";
import { Domain, DomainHelpers } from "xchain-helpers/testing/Domain.sol";
import { LZBridgeTesting }      from "xchain-helpers/testing/bridges/LZBridgeTesting.sol";
import { LZGovBridgeReceiver }  from "xchain-helpers/receivers/LZGovBridgeReceiver.sol";
import { LZGovBridgeForwarder, MessagingFee } from "xchain-helpers/forwarders/LZGovBridgeForwarder.sol";

import { SSRAuthOracle }                 from "src/SSRAuthOracle.sol";
import { SSROracleForwarderLZGovBridge } from "src/forwarders/SSROracleForwarderLZGovBridge.sol";
import { ISSROracle }                    from "src/interfaces/ISSROracle.sol";
import { ISUSDS }                        from "src/interfaces/ISUSDS.sol";

import { GovernanceOAppReceiverMock } from "lib/xchain-helpers/test/mocks/lz/GovernanceOAppReceiverMock.sol";
import { GovernanceOAppSenderMock }   from "test/mocks/GovernanceOAppSenderMock.sol";

interface IChainLog {
    function getAddress(bytes32) external view returns (address);
}

interface ISUSDS4626 {
    function convertToAssets(uint256 shares) external view returns (uint256);
}

contract SSROracleIntegrationLZGovBridgeBaseTest is Test {

    event LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData susdsData);

    using DomainHelpers   for *;
    using LZBridgeTesting for *;
    using OptionsBuilder  for bytes;

    IChainLog constant chainlog = IChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address susds;

    address constant SOURCE_ENDPOINT      = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32  sourceEndpointId      = LZGovBridgeForwarder.ENDPOINT_ID_ETHEREUM;
    uint32  destinationEndpointId = 30184;
    address destinationEndpoint   = 0x1a44076050125825900e736c501f859c50fE728c;

    Domain mainnet;
    Domain remote;
    Bridge bridge;

    SSROracleForwarderLZGovBridge forwarder;

    SSRAuthOracle oracle;

    GovernanceOAppSenderMock   govOappSender;
    GovernanceOAppReceiverMock govOappReceiver;
    LZGovBridgeReceiver        govBridgeReceiver;

    function setUp() public {
        mainnet = getChain("mainnet").createSelectFork();

        susds = chainlog.getAddress("SUSDS");

        remote = getChain("base").createFork();
        bridge = LZBridgeTesting.createLZBridge(mainnet, remote);

        // Precompute addresses (nonce is shared across forks for persistent contracts)
        uint256 nonce = vm.getNonce(address(this));
        address expectedGovOappSender = vm.computeCreateAddress(address(this), nonce);
        address expectedForwarder     = vm.computeCreateAddress(address(this), nonce + 4);

        // --- Mainnet: deploy GovernanceOAppSender ---
        govOappSender = new GovernanceOAppSenderMock(SOURCE_ENDPOINT, address(this));
        assertEq(address(govOappSender), expectedGovOappSender);

        // --- Remote: deploy all destination contracts ---
        remote.selectFork();

        govOappReceiver = new GovernanceOAppReceiverMock(
            sourceEndpointId,
            bytes32(uint256(uint160(address(govOappSender)))),
            destinationEndpoint,
            address(this)
        );

        oracle = new SSRAuthOracle();

        govBridgeReceiver = new LZGovBridgeReceiver(
            address(govOappReceiver),
            sourceEndpointId,
            expectedForwarder,
            address(oracle)
        );

        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(govBridgeReceiver));

        // --- Mainnet: deploy forwarder + configure GovernanceOAppSender ---
        mainnet.selectFork();

        forwarder = new SSROracleForwarderLZGovBridge(
            susds,
            address(govBridgeReceiver),
            address(govOappSender),
            destinationEndpointId
        );
        assertEq(address(forwarder), expectedForwarder);

        govOappSender.setPeer(
            destinationEndpointId,
            bytes32(uint256(uint160(address(govOappReceiver))))
        );
        govOappSender.setCanCallTarget(
            address(forwarder),
            destinationEndpointId,
            bytes32(uint256(uint160(address(govBridgeReceiver)))),
            true
        );
    }

    function test_constructor_forwarder() public {
        mainnet.selectFork();

        SSROracleForwarderLZGovBridge f = new SSROracleForwarderLZGovBridge(
            susds,
            makeAddr("receiver"),
            address(govOappSender),
            destinationEndpointId
        );

        assertEq(address(f.susds()),  susds);
        assertEq(f.l2Oracle(),        makeAddr("receiver"));
        assertEq(f.govOapp(),         address(govOappSender));
        assertEq(f.dstEid(),          destinationEndpointId);
    }

    function test_xchain_relay() public {
        remote.selectFork();

        assertEq(oracle.getSSR(), 0);
        assertEq(oracle.getChi(), 0);
        assertEq(oracle.getRho(), 0);

        mainnet.selectFork();

        // Read current sUSDS values
        uint256 currSSR = ISUSDS(susds).ssr();
        uint256 currChi = uint256(ISUSDS(susds).chi());
        uint256 currRho = uint256(ISUSDS(susds).rho());

        // Anchor the time to rho so conversion rate is predictable
        vm.warp(currRho + 30 days);

        ISSROracle.SUSDSData memory data = forwarder.getLastSeenSUSDSData();
        assertEq(data.ssr,                   0);
        assertEq(data.chi,                   0);
        assertEq(data.rho,                   0);
        assertEq(forwarder.getLastSeenSSR(), 0);
        assertEq(forwarder.getLastSeenChi(), 0);
        assertEq(forwarder.getLastSeenRho(), 0);

        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);
        MessagingFee memory fee = forwarder.quote(extraOptions);
        vm.deal(address(this), fee.nativeFee);

        vm.expectEmit(address(forwarder));
        emit LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData({
            ssr: uint96(currSSR),
            chi: uint120(currChi),
            rho: uint40(currRho) // timestamp of last drip, doesn't change on `refresh`
        }));
        forwarder.refresh{ value: fee.nativeFee }(extraOptions, address(this));

        data = forwarder.getLastSeenSUSDSData();
        assertEq(data.ssr,                   currSSR);
        assertEq(data.chi,                   currChi);
        assertEq(data.rho,                   currRho);
        assertEq(forwarder.getLastSeenSSR(), currSSR);
        assertEq(forwarder.getLastSeenChi(), currChi);
        assertEq(forwarder.getLastSeenRho(), currRho);

        bridge.relayMessagesToDestination(true, address(govOappSender), address(govOappReceiver));
        vm.warp(currRho + 30 days);

        assertEq(oracle.getSSR(), currSSR);
        assertEq(oracle.getChi(), currChi);
        assertEq(oracle.getRho(), currRho);

        // Verify the remote oracle conversion rate approximates mainnet sUSDS
        vm.warp(currRho + 90 days);
        uint256 remoteRate = oracle.getConversionRate();
        mainnet.selectFork();
        vm.warp(currRho + 90 days);
        uint256 mainnetRate = ISUSDS4626(susds).convertToAssets(1e27);
        assertApproxEqRel(remoteRate, mainnetRate, 1e12);  // within 0.0001%
    }

}
