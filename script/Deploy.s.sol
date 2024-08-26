// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Gnosis } from "sparklend-address-registry/src/Gnosis.sol";

import { IDSRAuthOracle }                 from "src/interfaces/IDSRAuthOracle.sol";
import { DSRBalancerRateProviderAdapter } from "src/adapters/DSRBalancerRateProviderAdapter.sol";
import { DSRAuthOracle }                  from "src/DSRAuthOracle.sol";

import { DSROracleForwarderOptimism }    from "src/forwarders/DSROracleForwarderOptimism.sol";
import { DSROracleForwarderBaseChain }   from "src/forwarders/DSROracleForwarderBaseChain.sol";
import { DSROracleForwarderGnosis }      from "src/forwarders/DSROracleForwarderGnosis.sol";
import { DSROracleForwarderArbitrumOne } from "src/forwarders/DSROracleForwarderArbitrumOne.sol";

import { AMBReceiver }      from "xchain-helpers/receivers/AMBReceiver.sol";
import { ArbitrumReceiver } from "xchain-helpers/receivers/ArbitrumReceiver.sol";
import { OptimismReceiver } from "xchain-helpers/receivers/OptimismReceiver.sol";

contract Deploy is Script {

    address internal constant MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

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
        address receiver = deployReceiver(forwarder, address(oracle));
        require(receiver == expectedReceiver, "receiver mismatch");
        DSRBalancerRateProviderAdapter adapter = new DSRBalancerRateProviderAdapter(oracle);

        // Configure
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), receiver);
        if (admin != address(0)) {
            oracle.grantRole(oracle.DEFAULT_ADMIN_ROLE(), admin);
        }
        oracle.renounceRole(oracle.DEFAULT_ADMIN_ROLE(), deployer);
        vm.stopBroadcast();

        console.log("Deployed Forwarder at:                     ", forwarder);
        console.log("Deployed Receiver at:                      ", receiver);
        console.log("Deployed DSRAuthOracle at:                 ", address(oracle));
        console.log("Deployed DSRBalancerRateProviderAdapter at:", address(adapter));
    }

    function deployForwarder(address) internal virtual returns (address) {
        return address(0);
    }

    function deployReceiver(address, address) internal virtual returns (address) {
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

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        return address(new OptimismReceiver(forwarder, oracle));
    }

}

contract DeployBase is Deploy {
    
    function run() external {
        deploy(getChain("base").rpcUrl);
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderBaseChain(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        return address(new OptimismReceiver(forwarder, oracle));
    }

}

contract DeployWorldChain is Deploy {
    
    function run() external {
        deploy(vm.envString("WORLD_CHAIN_RPC_URL"));
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderBaseChain(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        return address(new OptimismReceiver(forwarder, oracle));
    }

}

contract DeployGnosis is Deploy {
    
    function run() external {
        deploy(getChain("gnosis_chain").rpcUrl);
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderGnosis(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        return address(new AMBReceiver(Gnosis.L2_AMB, bytes32(uint256(1)), forwarder, oracle));
    }

}

contract DeployArbitrumOne is Deploy {
    
    function run() external {
        deploy(getChain("arbitrum_one").rpcUrl);
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new DSROracleForwarderArbitrumOne(MCD_POT, receiver));
    }

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        return address(new ArbitrumReceiver(forwarder, oracle));
    }

}
