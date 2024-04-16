// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Gnosis } from "sparklend-address-registry/src/Gnosis.sol";

import { IDSRAuthOracle }                 from "src/interfaces/IDSRAuthOracle.sol";
import { DSRBalancerRateProviderAdapter } from "src/adapters/DSRBalancerRateProviderAdapter.sol";
import { DSRAuthOracle }                  from "src/DSRAuthOracle.sol";

import { DSROracleForwarderOptimism }    from "src/forwarders/DSROracleForwarderOptimism.sol";
import { DSROracleForwarderBase }        from "src/forwarders/DSROracleForwarderBase.sol";
import { DSROracleForwarderGnosis }      from "src/forwarders/DSROracleForwarderGnosis.sol";
import { DSROracleForwarderArbitrumOne } from "src/forwarders/DSROracleForwarderArbitrumOne.sol";

import { DSROracleReceiverOptimism } from "src/receivers/DSROracleReceiverOptimism.sol";
import { DSROracleReceiverGnosis }   from "src/receivers/DSROracleReceiverGnosis.sol";
import { DSROracleReceiverArbitrum } from "src/receivers/DSROracleReceiverArbitrum.sol";

contract Deploy is Script {

    address internal constant MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    uint256 internal constant DSR_1000APY = 1.000000076036763190083298291e27;

    function deploy(string memory remoteRpcUrl) internal {
        address deployer = msg.sender;
        address admin    = vm.envOr("ORACLE_ADMIN", address(0));

        vm.createSelectFork(remoteRpcUrl);

        uint256 nonce = vm.getNonce(deployer);

        vm.createSelectFork(getChain("mainnet").rpcUrl);

        vm.startBroadcast();
        address expectedReceiver = vm.computeCreateAddress(deployer, nonce + 1);
        address forwarder        = deployForwarder(expectedReceiver);
        vm.stopBroadcast();

        vm.createSelectFork(remoteRpcUrl);

        vm.startBroadcast();
        DSRAuthOracle oracle = new DSRAuthOracle();
        address receiver = deployReceiver(forwarder, oracle);
        require(receiver == expectedReceiver, "receiver mismatch");
        DSRBalancerRateProviderAdapter adapter = new DSRBalancerRateProviderAdapter(oracle);

        // Configure
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), receiver);
        oracle.setMaxDSR(DSR_1000APY);
        if (admin != address(0)) {
            oracle.grantRole(oracle.DEFAULT_ADMIN_ROLE(), admin);
        }
        oracle.renounceRole(oracle.DEFAULT_ADMIN_ROLE(), deployer);
        vm.stopBroadcast();

        console.log("Deployed Forwarder at:",                      forwarder);
        console.log("Deployed Receiver at:",                       receiver);
        console.log("Deployed DSRAuthOracle at:",                  address(oracle));
        console.log("Deployed DSRBalancerRateProviderAdapter at:", address(adapter));
    }

    function deployForwarder(address) internal virtual returns (address) {
        return address(0);
    }

    function deployReceiver(address, IDSRAuthOracle) internal virtual returns (address) {
        return address(0);
    }

}

contract DeployOptimism is Deploy {
    
    function run() external {
        deploy(getChain("optimism").rpcUrl);
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderOptimism(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, IDSRAuthOracle oracle) internal override returns (address) {
        return address(new DSROracleReceiverOptimism(forwarder, oracle));
    }

}

contract DeployBase is Deploy {
    
    function run() external {
        deploy(getChain("base").rpcUrl);
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderBase(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, IDSRAuthOracle oracle) internal override returns (address) {
        return address(new DSROracleReceiverOptimism(forwarder, oracle));
    }

}

contract DeployGnosis is Deploy {
    
    function run() external {
        deploy(getChain("gnosis_chain").rpcUrl);
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderGnosis(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, IDSRAuthOracle oracle) internal override returns (address) {
        return address(new DSROracleReceiverGnosis(Gnosis.L2_AMB, 1, forwarder, oracle));
    }

}

contract DeployArbitrumOne is Deploy {
    
    function run() external {
        deploy(getChain("arbitrum_one").rpcUrl);
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderArbitrumOne(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, IDSRAuthOracle oracle) internal override returns (address) {
        return address(new DSROracleReceiverArbitrum(forwarder, oracle));
    }

}
