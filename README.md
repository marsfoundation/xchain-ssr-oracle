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

These are bridge-specific messaging contracts. Forwarders permissionlessly relay `pot` data. Receivers decode this message and forward it to the `DSRAuthOracle`.

## Supported Chains

 * Optimism
 * Base
 * Gnosis Chain

 ## Examples of Usage

 Look in the integration tests for practical examples of what the deployment will look like.

***
*The IP in this repository was assigned to Mars SPC Limited in respect of the MarsOne SP*
