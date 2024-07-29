# XChain DSR Oracle

Reports the DSR values across various bridges. This is primarily used as an exchange rate between DAI (USD) and sDAI for use by DEXs in capital efficiency liquidity amplification. Provided the three pot values (`dsr`, `chi` and `rho`) are synced you can extrapolate an exact exchange rate to any point in the future for as long as the `dsr` value does not get updated on mainnet. Because this oracle does not need to be synced unless the `dsr` changes, it can use the chain's canonical bridge for maximum security.

## Contracts

### DSROracleBase

Common functionality shared between the Mainnet and XChain instances of the oracle. Contains convenience functions to fetch the conversion rate at various levels of precision trading off gas efficiency. Pot data is compressed into a single word to save SLOAD gas cost.

### DSRMainnetOracle

Mainnet instance pulls data directly from the `pot` as it is on the same chain. It's not clear the use case for this beyond consistency and some gas savings, but it was included none-the-less.

### DSRAuthOracle

Oracle receives data from an authorized data provider. This is intended to be one or more bridges which publish data to the oracle. Application-level sanity checks are included when new data is proposed to minimize damage in the event of a bridge being compromised. These sanity checks also enforce event ordering in case messages are relayed out of order. `maxDSR` is used as an upper bound to prevent exchange rates that are wildly different from reality. It is recommended to sync this oracle somewhat frequently to minimize the damage of a compromised bridge.

### Forwarders + Receivers

These are bridge-specific messaging contracts. Forwarders permissionlessly relay `pot` data. Receivers decode this message and forward it to the `DSRAuthOracle`. Please note that receivers are generic and part of the `xchain-helpers` repository.

## Supported Chains

 * Optimism
 * Base
 * Aribitrum One
 * Gnosis Chain

## Deployment Instructions

Run `make deploy-XXX` where XXX is one of the supported networks. Be sure to have the `ETH_FROM` environment variable set to the deployer address as well as the relevant environment variables set for RPCs and contract verification. You can see contract verification api key names in `foundry.toml`.

## Legacy Deployments

### Optimism

Forwarder (Ethereum): [0x4042127DecC0cF7cc0966791abebf7F76294DeF3](https://etherscan.io/address/0x4042127DecC0cF7cc0966791abebf7F76294DeF3#code)  
AuthOracle (Optimism): [0x33a3aB524A43E69f30bFd9Ae97d1Ec679FF00B64](https://optimistic.etherscan.io/address/0x33a3ab524a43e69f30bfd9ae97d1ec679ff00b64#code)  
Receiver (Optimism): [0xE206AEbca7B28e3E8d6787df00B010D4a77c32F3](https://optimistic.etherscan.io/address/0xE206AEbca7B28e3E8d6787df00B010D4a77c32F3#code)  
Balancer Rate Provider (Optimism): [0x15ACEE5F73b36762Ab1a6b7C98787b8148447898](https://optimistic.etherscan.io/address/0x15ACEE5F73b36762Ab1a6b7C98787b8148447898#code)  

### Base

Forwarder (Ethereum): [0x8Ed551D485701fe489c215E13E42F6fc59563e0e](https://etherscan.io/address/0x8Ed551D485701fe489c215E13E42F6fc59563e0e#code)  
AuthOracle (Base): [0x2Dd2a2Fe346B5704380EfbF6Bd522042eC3E8FAe](https://basescan.org/address/0x2Dd2a2Fe346B5704380EfbF6Bd522042eC3E8FAe#code)  
Receiver (Base): [0xaDEAf02Ddb5Bed574045050B8096307bE66E0676](https://basescan.org/address/0xaDEAf02Ddb5Bed574045050B8096307bE66E0676#code)  
Balancer Rate Provider (Base): [0xeC0C14Ea7fF20F104496d960FDEBF5a0a0cC14D0](https://basescan.org/address/0xeC0C14Ea7fF20F104496d960FDEBF5a0a0cC14D0#code)  

### Arbitrum

Forwarder (Ethereum): [0x7F36E7F562Ee3f320644F6031e03E12a02B85799](https://etherscan.io/address/0x7F36E7F562Ee3f320644F6031e03E12a02B85799#code)  
AuthOracle (Arbitrum): [0xE206AEbca7B28e3E8d6787df00B010D4a77c32F3](https://arbiscan.io/address/0xE206AEbca7B28e3E8d6787df00B010D4a77c32F3#code)  
Receiver (Arbitrum): [0xcA61540eC2AC74E6954FA558B4aF836d95eCb91b](https://arbiscan.io/address/0xcA61540eC2AC74E6954FA558B4aF836d95eCb91b#code)  
Balancer Rate Provider (Arbitrum): [0x73750DbD85753074e452B2C27fB9e3B0E75Ff3B8](https://arbiscan.io/address/0x73750DbD85753074e452B2C27fB9e3B0E75Ff3B8#code)  

***
*The IP in this repository was assigned to Mars SPC Limited in respect of the MarsOne SP*
