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
}

struct SSROracleLZGovBridgeConfig {
    address susds;
    address receiver;
    uint32  dstEid;
    address endpoint;
}

library SSROracleLZGovBridgeInit {

    ChainlogLike internal constant chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    function init(
        address                           forwarder,
        address                           govOappSender,
        SSROracleLZGovBridgeConfig memory cfg
    ) internal {

        // Forwarder sanity checks
        SSROracleForwarderLZGovBridgeLike _forwarder = SSROracleForwarderLZGovBridgeLike(forwarder);
        require(_forwarder.susds()    == cfg.susds,     "SSROracleLZGovBridgeInit/susds-mismatch");
        require(_forwarder.l2Oracle() == cfg.receiver,  "SSROracleLZGovBridgeInit/receiver-mismatch");
        require(_forwarder.govOapp()  == govOappSender, "SSROracleLZGovBridgeInit/gov-oapp-mismatch");
        require(_forwarder.dstEid()   == cfg.dstEid,    "SSROracleLZGovBridgeInit/dst-eid-mismatch");

        // GovernanceOAppSender sanity checks
        GovOappSenderLike _govOappSender = GovOappSenderLike(govOappSender);
        require(_govOappSender.endpoint() == cfg.endpoint,                           "SSROracleLZGovBridgeInit/endpoint-mismatch");
        require(_govOappSender.owner()    == chainlog.getAddress("MCD_PAUSE_PROXY"), "SSROracleLZGovBridgeInit/owner-mismatch");

        // Write to chainlog
        chainlog.setAddress("LZ_SSR_FORWARDER", forwarder);
        chainlog.setAddress("LZ_SSR_SENDER",    govOappSender);
    }

}
