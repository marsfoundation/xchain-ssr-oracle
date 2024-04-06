#!/bin/bash

REMOTE_NETWORK_NAME="$1"
BURN_ACCESS="$2"

if [ -z "$REMOTE_NETWORK_NAME" ]; then
    echo "Usage: $0 <REMOTE_NETWORK_NAME>"
    exit 1
fi

if [ "$REMOTE_NETWORK_NAME" == "optimism" ]; then
    FORWARDER_CONTRACT="DSROracleForwarderOptimism"
    RECEIVER_CONTRACT="DSROracleReceiverOptimism"
    REMOTE_RPC="$OPTIMISM_RPC_URL"
    REMOTE_VERIFY_API_KEY="$OPTIMISM_VERIFY_API_KEY"
elif [ "$REMOTE_NETWORK_NAME" == "base" ]; then
    FORWARDER_CONTRACT="DSROracleForwarderBase"
    RECEIVER_CONTRACT="DSROracleReceiverOptimism"
    REMOTE_RPC="$BASE_RPC_URL"
    REMOTE_VERIFY_API_KEY="$BASE_VERIFY_API_KEY"
elif [ "$REMOTE_NETWORK_NAME" == "gnosis" ]; then
    FORWARDER_CONTRACT="DSROracleForwarderGnosis"
    RECEIVER_CONTRACT="DSROracleReceiverGnosis"
    REMOTE_RPC="$GNOSIS_CHAIN_RPC_URL"
    REMOTE_VERIFY_API_KEY="$GNOSIS_VERIFY_API_KEY"
else
    echo "Invalid network name: '$REMOTE_NETWORK_NAME'"
    exit 1
fi

if [ -z "$MAINNET_RPC_URL" ]; then
    echo "'MAINNET_RPC_URL' is not defined"
    exit 1
fi

if [ -z "$REMOTE_RPC" ]; then
    echo "Missing remote RPC URL environment variable for '$REMOTE_NETWORK_NAME'"
    exit 1
fi

if [ -z "$REMOTE_VERIFY_API_KEY" ]; then
    echo "Missing contract verification environment variable for '$REMOTE_NETWORK_NAME'"
    exit 1
fi

if [ -z "$ETH_FROM" ]; then
    echo "'ETH_FROM' is not defined"
    exit 1
fi

MAINNET_NONCE1=`cast nonce --rpc-url "$MAINNET_RPC_URL" $ETH_FROM`
REMOTE_NONCE1=`cast nonce --rpc-url "$REMOTE_RPC" $ETH_FROM`
REMOTE_NONCE2=`bc <<< "$REMOTE_NONCE1 + 1"`
REMOTE_NONCE3=`bc <<< "$REMOTE_NONCE1 + 2"`
FORWARDER_ADDRESS=`cast compute-address --nonce "$MAINNET_NONCE1" $ETH_FROM | cut -c 19-`
AUTH_ORACLE_ADDRESS=`cast compute-address --nonce "$REMOTE_NONCE1" $ETH_FROM | cut -c 19-`
RECEIVER_ADDRESS=`cast compute-address --nonce "$REMOTE_NONCE2" $ETH_FROM | cut -c 19-`
BALANCER_RATE_PROVIDER_ADDRESS=`cast compute-address --nonce "$REMOTE_NONCE3" $ETH_FROM | cut -c 19-`

# Set the DSR APY (1000 = 1000% APY)
MAX_DSR_APY=1000
MAX_DSR_RATE=`bc -l <<< "scale=27; e( l($MAX_DSR_APY/100 + 1)/(60 * 60 * 24 * 365) )" | tr -d '.'`

if [ "$BURN_ACCESS" = "--burn-access" ]; then
    echo "Deploying contracts then burning the access (Max DSR = $MAX_DSR_APY%)"
else
    echo "Deploying contracts (Max DSR = $MAX_DSR_APY%)"
fi
echo "Forwarder: $FORWARDER_ADDRESS"
echo "AuthOracle: $AUTH_ORACLE_ADDRESS"
echo "Receiver: $RECEIVER_ADDRESS"
echo "Balancer Rate Provider: $BALANCER_RATE_PROVIDER_ADDRESS"

MCD_POT=0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7

# Deployment
forge create $FORWARDER_CONTRACT --rpc-url "$MAINNET_RPC_URL" --verify --constructor-args $MCD_POT $RECEIVER_ADDRESS > /dev/null
ETHERSCAN_API_KEY="$REMOTE_VERIFY_API_KEY" forge create DSRAuthOracle --rpc-url "$REMOTE_RPC" --verify > /dev/null
ETHERSCAN_API_KEY="$REMOTE_VERIFY_API_KEY" forge create $RECEIVER_CONTRACT --rpc-url "$REMOTE_RPC" --verify --constructor-args $FORWARDER_ADDRESS $AUTH_ORACLE_ADDRESS > /dev/null
ETHERSCAN_API_KEY="$REMOTE_VERIFY_API_KEY" forge create DSRBalancerRateProviderAdapter --rpc-url "$REMOTE_RPC" --verify --constructor-args $AUTH_ORACLE_ADDRESS > /dev/null

# Configuration
cast send $AUTH_ORACLE_ADDRESS --rpc-url "$REMOTE_RPC" 'setMaxDSR(uint256)' $MAX_DSR_RATE > /dev/null
cast send $AUTH_ORACLE_ADDRESS --rpc-url "$REMOTE_RPC" 'grantRole(bytes32,address)' `cast keccak DATA_PROVIDER_ROLE` $RECEIVER_ADDRESS > /dev/null

if [ "$BURN_ACCESS" = "--burn-access" ]; then
    cast send $AUTH_ORACLE_ADDRESS --rpc-url "$REMOTE_RPC" 'renounceRole(bytes32,address)' 0x0000000000000000000000000000000000000000000000000000000000000000 $ETH_FROM > /dev/null
fi
