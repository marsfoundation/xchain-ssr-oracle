// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import { ISSRAuthOracle, ISSROracle } from '../interfaces/ISSRAuthOracle.sol';

import { SSROracleForwarderBase } from './SSROracleForwarderBase.sol';

interface GovOappLike {
    function quoteTx(TxParams calldata, bool) external view returns (MessagingFee calldata);
    function sendTx(TxParams calldata, MessagingFee calldata, address) external payable returns (MessagingReceipt memory);
}

struct TxParams {
    uint32  dstEid;
    bytes32 dstTarget;
    bytes   dstCallData;
    bytes   extraOptions;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64  nonce;
    MessagingFee fee;
}

contract SSROracleForwarderLzGovBridge is SSROracleForwarderBase {

    using SafeCast for uint256;

    GovOappLike public immutable govOapp;
    uint32      public immutable dstEid;

    constructor(
        address _susds,
        address _l2Oracle,
        address _govOapp,
        uint32  _dstEid
    ) SSROracleForwarderBase(_susds, _l2Oracle) {
        govOapp = GovOappLike(_govOapp);
        dstEid  = _dstEid;
    }

    function _susdsData() internal view returns (ISSROracle.SUSDSData memory) {
        return ISSROracle.SUSDSData({
            ssr: susds.ssr().toUint96(),
            chi: uint256(susds.chi()).toUint120(),
            rho: uint256(susds.rho()).toUint40()
        });
    }

    function _dstCallData(ISSROracle.SUSDSData memory susdsData) internal pure returns (bytes memory) {
        return abi.encodeCall(ISSRAuthOracle.setSUSDSData, (susdsData));
    }

    function quote(bytes calldata extraOptions) external view returns (MessagingFee memory) {
        return govOapp.quoteTx(
            TxParams({
                dstEid:       dstEid,
                dstTarget:    bytes32(uint256(uint160(l2Oracle))),
                dstCallData:  _dstCallData(_susdsData()),
                extraOptions: extraOptions
            }),
            false
        );
    }

    function refresh(bytes calldata extraOptions) public payable returns (MessagingReceipt memory) {
        TxParams memory txParams = TxParams({
            dstEid:       dstEid,
            dstTarget:    bytes32(uint256(uint160(l2Oracle))),
            dstCallData:  _packMessage(),
            extraOptions: extraOptions
        });

        MessagingFee memory fee;
        fee.nativeFee = msg.value;

        return govOapp.sendTx{ value: msg.value }(txParams, fee, msg.sender);
    }

}
