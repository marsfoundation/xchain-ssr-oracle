// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Gnosis } from "sparklend-address-registry/src/Gnosis.sol";

import { SSRBalancerRateProviderAdapter }  from "src/adapters/SSRBalancerRateProviderAdapter.sol";
import { SSRChainlinkRateProviderAdapter } from "src/adapters/SSRChainlinkRateProviderAdapter.sol";
import { SSRAuthOracle }                   from "src/SSRAuthOracle.sol";

import { SSROracleForwarderOptimism, OptimismForwarder }   from "src/forwarders/SSROracleForwarderOptimism.sol";
import { SSROracleForwarderGnosis }                        from "src/forwarders/SSROracleForwarderGnosis.sol";
import { SSROracleForwarderArbitrum, ArbitrumForwarder }   from "src/forwarders/SSROracleForwarderArbitrum.sol";
import { SSROracleForwarderLZGovBridge }                   from "src/forwarders/SSROracleForwarderLZGovBridge.sol";

import { AMBReceiver }         from "xchain-helpers/receivers/AMBReceiver.sol";
import { ArbitrumReceiver }    from "xchain-helpers/receivers/ArbitrumReceiver.sol";
import { OptimismReceiver }    from "xchain-helpers/receivers/OptimismReceiver.sol";
import { LZGovBridgeReceiver }   from "xchain-helpers/receivers/LZGovBridgeReceiver.sol";
import { LZGovBridgeForwarder } from "xchain-helpers/forwarders/LZGovBridgeForwarder.sol";

interface IChainLog {
    function getAddress(bytes32) external view returns (address);
}

contract Deploy is Script {

    IChainLog internal constant chainlog = IChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address internal susds;

    function deploy(string memory remoteRpcUrl) internal {
        address deployer = msg.sender;
        address admin    = vm.envOr("ORACLE_ADMIN", address(0));

        vm.createSelectFork(remoteRpcUrl);

        uint256 nonce = vm.getNonce(deployer);

        vm.createSelectFork(getChain("mainnet").rpcUrl);

        susds = chainlog.getAddress("SUSDS");

        vm.startBroadcast();
        address expectedReceiver = vm.computeCreateAddress(deployer, nonce + 1);
        address forwarder        = deployForwarder(expectedReceiver);
        vm.stopBroadcast();

        vm.createSelectFork(remoteRpcUrl);

        vm.startBroadcast();
        SSRAuthOracle oracle = new SSRAuthOracle();
        address receiver = deployReceiver(forwarder, address(oracle));
        require(receiver == expectedReceiver, "receiver mismatch");
        SSRBalancerRateProviderAdapter  balancerAdapter  = new SSRBalancerRateProviderAdapter(oracle);
        SSRChainlinkRateProviderAdapter chainlinkAdapter = new SSRChainlinkRateProviderAdapter(oracle);

        // Configure
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), receiver);
        if (admin != address(0)) {
            oracle.grantRole(oracle.DEFAULT_ADMIN_ROLE(), admin);
        }
        oracle.renounceRole(oracle.DEFAULT_ADMIN_ROLE(), deployer);
        vm.stopBroadcast();

        console.log("Deployed Forwarder at:                     ",  forwarder);
        console.log("Deployed Receiver at:                      ",  receiver);
        console.log("Deployed SSRAuthOracle at:                 ",  address(oracle));
        console.log("Deployed SSRBalancerRateProviderAdapter at:",  address(balancerAdapter));
        console.log("Deployed SSRChainlinkRateProviderAdapter at:", address(chainlinkAdapter));
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
        return address(new SSROracleForwarderOptimism(susds, receiver, OptimismForwarder.L1_CROSS_DOMAIN_OPTIMISM));
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
        return address(new SSROracleForwarderOptimism(susds, receiver, OptimismForwarder.L1_CROSS_DOMAIN_BASE));
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
        return address(new SSROracleForwarderOptimism(susds, receiver, OptimismForwarder.L1_CROSS_DOMAIN_WORLD_CHAIN));
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
        return address(new SSROracleForwarderGnosis(susds, receiver));
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
        return address(new SSROracleForwarderArbitrum(susds, receiver, ArbitrumForwarder.L1_CROSS_DOMAIN_ARBITRUM_ONE));
    }

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        return address(new ArbitrumReceiver(forwarder, oracle));
    }

}

contract DeployUnichain is Deploy {
    
    function run() external {
        deploy(vm.envString("UNICHAIN_RPC_URL"));
    }

    function deployForwarder(address receiver) internal override returns (address) {
        return address(new SSROracleForwarderOptimism(susds, receiver, OptimismForwarder.L1_CROSS_DOMAIN_UNICHAIN));
    }

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        return address(new OptimismReceiver(forwarder, oracle));
    }

}

// NOTE: GovernanceOAppSender and GovernanceOAppReceiver must be configured separately (e.g setPeer, setCanCallTarget) by the gov oapp owner after deployment.
contract DeployLZGovBridge is Deploy {

    function run() external {
        deploy(vm.envString("REMOTE_RPC_URL"));
    }

    function deployForwarder(address receiver) internal override returns (address) {
        uint32  dstEid        = uint32(vm.envUint("DST_EID"));
        address ssrOappSender = vm.envAddress("SSR_OAPP_SENDER");
        return address(new SSROracleForwarderLZGovBridge(susds, receiver, ssrOappSender, dstEid));
    }

    function deployReceiver(address forwarder, address oracle) internal override returns (address) {
        address ssrOappReceiver = vm.envAddress("SSR_OAPP_RECEIVER");
        return address(new LZGovBridgeReceiver(ssrOappReceiver, LZGovBridgeForwarder.ENDPOINT_ID_ETHEREUM, forwarder, oracle));
    }

}
