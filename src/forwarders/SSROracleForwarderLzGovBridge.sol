// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import { ISSRAuthOracle, ISSROracle } from '../interfaces/ISSRAuthOracle.sol';
import { SSROracleForwarderBase } from './SSROracleForwarderBase.sol';
import { LzGovBridgeForwarder, MessagingFee, MessagingReceipt } from 'xchain-helpers/forwarders/LzGovBridgeForwarder.sol';

contract SSROracleForwarderLzGovBridge is SSROracleForwarderBase {

    using SafeCast for uint256;

    address public immutable govOapp;
    uint32  public immutable dstEid;

    constructor(
        address _susds,
        address _l2Oracle, // The receiver on the remote chains
        address _govOapp,
        uint32  _dstEid
    ) SSROracleForwarderBase(_susds, _l2Oracle) {
        govOapp = _govOapp;
        dstEid  = _dstEid;
    }

    function quote(bytes calldata extraOptions) external view returns (MessagingFee memory) {
        return LzGovBridgeForwarder.quote({
            govOapp:      govOapp,
            dstEid:       dstEid,
            dstTarget:    l2Oracle,
            message:      abi.encodeCall(ISSRAuthOracle.setSUSDSData, (ISSROracle.SUSDSData({
                ssr: susds.ssr().toUint96(),
                chi: uint256(susds.chi()).toUint120(),
                rho: uint256(susds.rho()).toUint40()
            }))),
            extraOptions: extraOptions
        });
    }

    function refresh(bytes calldata extraOptions) public payable returns (MessagingReceipt memory) {
        return LzGovBridgeForwarder.sendMessage({
            govOapp:       govOapp,
            dstEid:        dstEid,
            dstTarget:     l2Oracle,
            message:       _packMessage(),
            extraOptions:  extraOptions,
            refundAddress: msg.sender
        });
    }

}
