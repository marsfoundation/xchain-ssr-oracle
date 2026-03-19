// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { OptionsBuilder } from "layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import { Bridge }                from "xchain-helpers/testing/Bridge.sol";
import { Domain, DomainHelpers } from "xchain-helpers/testing/Domain.sol";
import { LZBridgeTesting }      from "xchain-helpers/testing/bridges/LZBridgeTesting.sol";
import { LZForwarder }          from "xchain-helpers/forwarders/LZForwarder.sol";
import { LZGovBridgeReceiver }  from "xchain-helpers/receivers/LZGovBridgeReceiver.sol";
import { MessagingFee } from "xchain-helpers/forwarders/LZGovBridgeForwarder.sol";

import { SSRAuthOracle }                 from "src/SSRAuthOracle.sol";
import { SSROracleForwarderLZGovBridge } from "src/forwarders/SSROracleForwarderLZGovBridge.sol";
import { ISSROracle }                    from "src/interfaces/ISSROracle.sol";
import { ISUSDS }                        from "src/interfaces/ISUSDS.sol";

import { GovernanceOAppReceiverMock } from "lib/xchain-helpers/test/mocks/lz/GovernanceOAppReceiverMock.sol";

interface IChainLog {
    function getAddress(bytes32) external view returns (address);
}

interface ISUSDS4626 {
    function convertToAssets(uint256 shares) external view returns (uint256);
}

interface IGovOappSender {
    function owner() external view returns (address);
    function setPeer(uint32 _eid, bytes32 _peer) external;
    function setCanCallTarget(address _srcSender, uint32 _dstEid, bytes32 _dstTarget, bool _canCall) external;
}

contract SSROracleIntegrationLZGovBridgeBaseTest is Test {

    event LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData susdsData);

    using DomainHelpers   for *;
    using LZBridgeTesting for *;
    using OptionsBuilder  for bytes;

    IChainLog constant chainlog = IChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address susds;
    address govOappSender;

    uint32 sourceEndpointId      = LZForwarder.ENDPOINT_ID_ETHEREUM;
    uint32 destinationEndpointId = LZForwarder.ENDPOINT_ID_BASE;

    address destinationEndpoint = LZForwarder.ENDPOINT_BASE;

    Domain mainnet;
    Domain remote;
    Bridge bridge;

    SSROracleForwarderLZGovBridge forwarder;

    SSRAuthOracle oracle;

    GovernanceOAppReceiverMock govOappReceiver;
    LZGovBridgeReceiver        govBridgeReceiver;

    function setUp() public {
        mainnet = getChain("mainnet").createSelectFork();

        susds         = chainlog.getAddress("SUSDS");
        govOappSender = chainlog.getAddress("LZ_GOV_SENDER");

        remote = getChain("base").createFork();
        bridge = LZBridgeTesting.createLZBridge(mainnet, remote);

        // Precompute forwarder address (nonce is shared across forks for persistent contracts)
        address expectedForwarder = vm.computeCreateAddress(address(this), vm.getNonce(address(this)) + 3);

        // --- Remote: deploy all destination contracts ---
        remote.selectFork();

        govOappReceiver = new GovernanceOAppReceiverMock(
            sourceEndpointId,
            bytes32(uint256(uint160(govOappSender))),
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
            govOappSender,
            destinationEndpointId
        );
        assertEq(address(forwarder), expectedForwarder);

        address govOwner = IGovOappSender(govOappSender).owner();
        vm.startPrank(govOwner);
        IGovOappSender(govOappSender).setPeer(
            destinationEndpointId,
            bytes32(uint256(uint160(address(govOappReceiver))))
        );
        IGovOappSender(govOappSender).setCanCallTarget(
            address(forwarder),
            destinationEndpointId,
            bytes32(uint256(uint160(address(govBridgeReceiver)))),
            true
        );
        vm.stopPrank();
    }

    function test_constructor_forwarder() public {
        mainnet.selectFork();

        SSROracleForwarderLZGovBridge f = new SSROracleForwarderLZGovBridge(
            susds,
            makeAddr("receiver"),
            govOappSender,
            destinationEndpointId
        );

        assertEq(address(f.susds()),  susds);
        assertEq(f.l2Oracle(),        makeAddr("receiver"));
        assertEq(f.govOapp(),         govOappSender);
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

        bridge.relayMessagesToDestination(true, govOappSender, address(govOappReceiver));
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
