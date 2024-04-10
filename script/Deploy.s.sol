// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { DSROracleForwarderOptimism } from "src/forwarders/DSROracleForwarderOptimism.sol";

contract Deploy is Script {

    address internal constant MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address internal constant ADMIN   = address(0);  // Leave address(0) to burn admin access

    uint256 internal constant DSR_1000APY = 1.000000076036763190083298291e27;

    function deploy(string memory remoteRpcUrl) internal {
        address deployer = msg.sender;

        vm.createSelectFork(getChain("mainnet").rpcUrl);

        address expectedReceiver = vm.computeCreateAddress(address(this), 5);
        address forwarder = deployForwarder(expectedReceiver);

        vm.createSelectFork(remoteRpcUrl);

        DSRAuthOracle oracle = new DSRAuthOracle();
        DSROracleReceiverOptimism receiver = new DSROracleReceiverOptimism(address(forwarder), oracle);
        assertEq(address(receiver), expectedReceiver);
        DSRBalancerRateProviderAdapter adapter = new DSRBalancerRateProviderAdapter(address(oracle));

        // Configure
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));
        oracle.setMaxDSR(DSR_1000APY);
        if (ADMIN != address(0)) {
            oracle.grantRole(oracle.DEFAULT_ADMIN_ROLE(), ADMIN);
        }
        oracle.renounceRole(oracle.DEFAULT_ADMIN_ROLE(), deployer);
    }

}

contract DeployOptimism is Deploy {
    
    function run() external {
        vm.startBroadcast();

        deploy(getChain("optimism").rpcUrl);

        vm.stopBroadcast();
    }

    function deployForwarder(address receiver) internal returns (address) {
        return address(new DSROracleForwarderOptimism(MCD_POT, receiver));
    }

}
