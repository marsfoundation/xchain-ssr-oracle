// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { OptionsBuilder } from "layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import { Bridge }                from "xchain-helpers/testing/Bridge.sol";
import { Domain, DomainHelpers } from "xchain-helpers/testing/Domain.sol";
import { LZBridgeTesting }      from "xchain-helpers/testing/bridges/LZBridgeTesting.sol";
import { LZComposeReceiver }    from "xchain-helpers/receivers/LZComposeReceiver.sol";
import { MessagingFee }         from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { SSRAuthOracle }         from "src/SSRAuthOracle.sol";
import { SSROracleForwarderLZ }  from "src/forwarders/SSROracleForwarderLZ.sol";
import { ISSROracle }            from "src/interfaces/ISSROracle.sol";
import { ISUSDS }                from "src/interfaces/ISUSDS.sol";

interface IChainLog {
    function getAddress(bytes32) external view returns (address);
}

interface IEndpoint {
    function delegates(address) external view returns (address);
}

interface ISUSDS4626 {
    function convertToAssets(uint256 shares) external view returns (uint256);
}

contract SSROracleIntegrationLZTest is Test {

    event LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData susdsData);

    using DomainHelpers   for *;
    using LZBridgeTesting for *;
    using OptionsBuilder  for bytes;

    IChainLog constant chainlog = IChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address susds;

    uint32  constant SOURCE_EID           = 30101;
    address constant SOURCE_ENDPOINT      = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32  constant DESTINATION_EID      = 30184;
    address constant DESTINATION_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    Domain mainnet;
    Domain remote;
    Bridge bridge;

    SSROracleForwarderLZ forwarder;
    SSRAuthOracle        oracle;
    LZComposeReceiver    receiver;

    function setUp() public {
        mainnet = getChain("mainnet").createSelectFork();

        susds = chainlog.getAddress("SUSDS");

        remote = getChain("base").createFork();
        bridge = LZBridgeTesting.createLZBridge(mainnet, remote);

        // --- Deploy.s.sol flow ---
        // We do not include most of the OAPP configurations
        uint256 nonce = vm.getNonce(address(this));
        address expectedReceiver = vm.computeCreateAddress(address(this), nonce + 2); // forwarder(+0), oracle(+1), receiver(+2)

        forwarder = new SSROracleForwarderLZ(
            susds,
            expectedReceiver,
            SOURCE_ENDPOINT,
            address(this),
            address(this),
            DESTINATION_EID
        );

        remote.selectFork();

        oracle = new SSRAuthOracle();

        receiver = new LZComposeReceiver({
            _destinationEndpoint : DESTINATION_ENDPOINT,
            _srcEid              : SOURCE_EID,
            _sourceAuthority     : bytes32(uint256(uint160(address(forwarder)))),
            _target              : address(oracle),
            _delegate            : address(this),
            _owner               : address(this)
        });
        assertEq(address(receiver), expectedReceiver);

        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));
        oracle.renounceRole(oracle.DEFAULT_ADMIN_ROLE(), address(this));

        // --- Configure forwarder OApp (only setPeer is included) ---
        mainnet.selectFork();
        forwarder.setPeer(
            DESTINATION_EID,
            bytes32(uint256(uint160(address(receiver))))
        );
    }

    function test_constructor_forwarder() public {
        mainnet.selectFork();

        address delegate_ = makeAddr("testDelegate");
        SSROracleForwarderLZ f = new SSROracleForwarderLZ(
            susds,
            makeAddr("receiver"),
            SOURCE_ENDPOINT,
            delegate_,
            address(this),
            DESTINATION_EID
        );

        assertEq(address(f.susds()),    susds);
        assertEq(f.l2Oracle(),          makeAddr("receiver"));
        assertEq(f.dstEid(),            DESTINATION_EID);
        assertEq(address(f.endpoint()), SOURCE_ENDPOINT);
        assertEq(f.owner(),             address(this));
        assertEq(IEndpoint(SOURCE_ENDPOINT).delegates(address(f)), delegate_);
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
        assertEq(data.ssr, 0);
        assertEq(data.chi, 0);
        assertEq(data.rho, 0);

        bytes memory extraOptions = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(200_000, 0)
            .addExecutorLzComposeOption(0, 200_000, 0);
        MessagingFee memory fee = forwarder.quote(extraOptions);
        vm.deal(address(this), fee.nativeFee);

        vm.expectEmit(address(forwarder));
        emit LastSeenSUSDSDataUpdated(ISSROracle.SUSDSData({
            ssr: uint96(currSSR),
            chi: uint120(currChi),
            rho: uint40(currRho)
        }));
        forwarder.refresh{ value: fee.nativeFee }(extraOptions, address(this));

        data = forwarder.getLastSeenSUSDSData();
        assertEq(data.ssr, currSSR);
        assertEq(data.chi, currChi);
        assertEq(data.rho, currRho);

        bridge.relayMessagesToDestination(true, address(forwarder), address(receiver));

        // Oracle should NOT be updated yet (deferred to lzCompose)
        assertEq(oracle.getSSR(), 0);
        assertEq(oracle.getChi(), 0);
        assertEq(oracle.getRho(), 0);

        bridge.relayComposeMessagesToDestination(true);
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
