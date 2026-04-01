// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { OAppSender, OAppCore, MessagingFee, MessagingReceipt } from "layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { OAppOptionsType3 } from "layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";

struct TxParams {
    uint32  dstEid;
    bytes32 dstTarget;
    bytes   dstCallData;
    bytes   extraOptions;
}

contract GovernanceOAppSenderMock is OAppSender, OAppOptionsType3 {

    uint16 public constant SEND_TX = 1;

    mapping(address srcSender => mapping(uint32 dstEid => mapping(bytes32 dstTarget => bool canCall))) public canCallTarget;

    constructor(
        address _endpoint,
        address _owner
    ) OAppCore(_endpoint, _owner) Ownable(_owner) {}

    function setPeer(uint32 _eid, bytes32 _peer) public override onlyOwner {
        _setPeer(_eid, _peer);
    }

    function setCanCallTarget(address _srcSender, uint32 _dstEid, bytes32 _dstTarget, bool _canCall) external onlyOwner {
        canCallTarget[_srcSender][_dstEid][_dstTarget] = _canCall;
    }

    function quoteTx(TxParams calldata _params, bool _payInLzToken) external view returns (MessagingFee memory fee) {
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(_params);
        return _quote(_params.dstEid, message, options, _payInLzToken);
    }

    function sendTx(
        TxParams calldata _params,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt) {
        require(canCallTarget[msg.sender][_params.dstEid][_params.dstTarget], "GovernanceOAppSenderMock/cannot-call-target");

        (bytes memory message, bytes memory options) = _buildMsgAndOptions(_params);
        return _lzSend(_params.dstEid, message, options, _fee, _refundAddress);
    }

    function _buildMsgAndOptions(TxParams calldata _params) internal view returns (bytes memory, bytes memory) {
        bytes32 msgSenderBytes32 = bytes32(uint256(uint160(msg.sender)));
        bytes memory message = abi.encodePacked(msgSenderBytes32, _params.dstTarget, _params.dstCallData);
        bytes memory options = combineOptions(_params.dstEid, SEND_TX, _params.extraOptions);
        return (message, options);
    }

}
