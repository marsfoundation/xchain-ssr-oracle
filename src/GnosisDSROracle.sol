// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { DSROracleBase, IDSROracle } from './DSROracleBase.sol';

interface IAMB {
    function messageSender() external view returns (address);
    function messageSourceChainId() external view returns (bytes32);
}

/**
 * @title  GnosisDSROracle
 * @notice DSR Oracle that sits on Gnosis Chain.
 */
contract GnosisDSROracle is DSROracleBase {

    error UnauthorizedAMB();
    error UnauthorizedChainId();
    error UnauthorizedController();

    // Address of the AMB contract forwarding the cross-chain transaction from Ethereum
    IAMB public amb;
    // Address of the orginating sender of the message
    address public relayer;
    // Chain ID of the origin
    bytes32 public chainId;

    constructor(address _amb, address _relayer, bytes32 _chainId) {
        amb = IAMB(_amb);
        relayer = _relayer;
        chainId = _chainId;
    }

    modifier onlyValid() {
        if (msg.sender != address(amb)) revert UnauthorizedAMB();
        if (amb.messageSourceChainId() != chainId) revert UnauthorizedChainId();
        if (amb.messageSender() != relayer) revert UnauthorizedController();
        _;
    }

    function setData(IDSROracle.PotData calldata data) external onlyValid {
        // Only accept increasing values of rho in case of message reordering
        require(data.rho > _data.rho, 'GnosisDSROracle: INVALID_RHO');
        _data = data;
    }

}
