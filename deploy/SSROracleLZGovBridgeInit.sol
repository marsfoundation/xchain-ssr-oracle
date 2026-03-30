// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

interface ChainlogLike {
    function getAddress(bytes32) external view returns (address);
    function setAddress(bytes32, address) external;
}

interface SSROracleForwarderLZGovBridgeLike {
    function susds()    external view returns (address);
    function l2Oracle() external view returns (address);
    function govOapp()  external view returns (address);
    function dstEid()   external view returns (uint32);
}

interface GovOappSenderLike {
    function endpoint() external view returns (address);
    function owner()    external view returns (address);
    function peers(uint32) external view returns (bytes32);
    function canCallTarget(address, uint32, bytes32) external view returns (bool);
    function setCanCallTarget(address, uint32, bytes32, bool) external;
}

interface EndpointLike {
    function delegates(address) external view returns (address);
}

struct OappSenderConfig {
    address endpoint;
}

struct ForwarderConfig {
    address receiver;
    uint32  dstEid;
    bytes32 peer;
}

library SSROracleLZGovBridgeInit {

    ChainlogLike internal constant chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    function initOappSender(
        address govOappSender,
        OappSenderConfig memory cfg
    ) internal {
        GovOappSenderLike _govOappSender = GovOappSenderLike(govOappSender);

        address pauseProxy = chainlog.getAddress("MCD_PAUSE_PROXY");
        address endpoint   = _govOappSender.endpoint();

        require(_govOappSender.owner()                          == pauseProxy,   "SSROracleLZGovBridgeInit/owner-mismatch");
        require(endpoint                                        == cfg.endpoint, "SSROracleLZGovBridgeInit/endpoint-mismatch");
        require(EndpointLike(endpoint).delegates(govOappSender) == pauseProxy,   "SSROracleLZGovBridgeInit/delegate-mismatch");

        chainlog.setAddress("LZ_SSR_SENDER", govOappSender);
    }

    function initForwarder(
        address                forwarder,
        address                govOappSender,
        bool                   setCanCall, // might not be needed initially if the forwarder was set during govOappSender deployment (which also allows testing)
        ForwarderConfig memory cfg
    ) internal {
        SSROracleForwarderLZGovBridgeLike _forwarder = SSROracleForwarderLZGovBridgeLike(forwarder);

        require(_forwarder.susds()    == chainlog.getAddress("SUSDS"), "SSROracleLZGovBridgeInit/susds-mismatch");
        require(_forwarder.l2Oracle() == cfg.receiver,                 "SSROracleLZGovBridgeInit/receiver-mismatch");
        require(_forwarder.govOapp()  == govOappSender,                "SSROracleLZGovBridgeInit/gov-oapp-mismatch");
        require(_forwarder.dstEid()   == cfg.dstEid,                   "SSROracleLZGovBridgeInit/dst-eid-mismatch");

        GovOappSenderLike _govOappSender = GovOappSenderLike(govOappSender);
        require(_govOappSender.peers(cfg.dstEid) == cfg.peer, "SSROracleLZGovBridgeInit/peer-mismatch");

        if (setCanCall) {
            _govOappSender.setCanCallTarget(forwarder, cfg.dstEid, bytes32(uint256(uint160(cfg.receiver))), true);
        }

        require(_govOappSender.canCallTarget(forwarder, cfg.dstEid, bytes32(uint256(uint160(cfg.receiver)))), "SSROracleLZGovBridgeInit/canCallTarget-mismatch");

        // We do not write to the chainlog, as with the existing SSR forwarders
    }

}
