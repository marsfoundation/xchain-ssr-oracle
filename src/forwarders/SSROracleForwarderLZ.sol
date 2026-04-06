// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import { Ownable }  from "openzeppelin-contracts/contracts/access/Ownable.sol";

import { OAppSender, OAppCore, MessagingFee, MessagingReceipt } from "layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { OAppOptionsType3 } from "layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";

import { ISSRAuthOracle, ISSROracle } from '../interfaces/ISSRAuthOracle.sol';
import { SSROracleForwarderBase }     from './SSROracleForwarderBase.sol';

contract SSROracleForwarderLZ is SSROracleForwarderBase, OAppSender, OAppOptionsType3 {

    using SafeCast for uint256;

    uint16 public constant SEND = 1;

    uint32 public immutable dstEid;

    constructor(
        address _susds,
        address _l2Oracle,
        address _endpoint,
        address _delegate,
        address _owner,
        uint32  _dstEid
    ) SSROracleForwarderBase(_susds, _l2Oracle) OAppCore(_endpoint, _delegate) Ownable(_owner) {
        dstEid = _dstEid;
    }

    function quote(bytes calldata extraOptions) external view returns (MessagingFee memory) {
        return _quote({
            _dstEid:       dstEid,
            _message:      abi.encodeCall(ISSRAuthOracle.setSUSDSData, (ISSROracle.SUSDSData({
                ssr: susds.ssr().toUint96(),
                chi: uint256(susds.chi()).toUint120(),
                rho: uint256(susds.rho()).toUint40()
            }))),
            _options:      combineOptions(dstEid, SEND, extraOptions),
            _payInLzToken: false
        });
    }

    /**
     * @notice Since LayerZero does not guarantee message ordering, it is advised to:
     *         1. Call `sUSDS.drip()` and then `refresh()` at least one block after any SSR update,
     *            ensuring a new `rho` that makes the remote oracle's ordering check effective.
     *         2. Monitor the remote chain's oracle to verify the update landed correctly.
     */
    function refresh(bytes calldata extraOptions, address refundAddress) public payable returns (MessagingReceipt memory) {
        return _lzSend({
            _dstEid:        dstEid,
            _message:       _packMessage(),
            _options:       combineOptions(dstEid, SEND, extraOptions),
            _fee:           MessagingFee(msg.value, 0),
            _refundAddress: refundAddress
        });
    }

}
