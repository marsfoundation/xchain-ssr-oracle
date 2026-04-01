# LZ Gov Bridge SSR Oracle — Deploy Sequence

## Phase 1: Deploy OApps (via LZ hardhat scripts)

1. Deploy `GovernanceOAppSender` on mainnet + configure routing (DVNs, executor, libraries) + set enforced options
2. Deploy `GovernanceOAppReceiver` on remote + configure routing
3. `setPeer` on both sides

## Phase 2: Deploy oracle infrastructure (see Deploy.s.sol) and whitelist forwarder

4. Deploy `SSROracleForwarderLZGovBridge` on mainnet (`receiver` = precomputed `LZGovBridgeReceiver` address)
5. Deploy `SSRAuthOracle` on remote
6. Deploy `LZGovBridgeReceiver` on remote
7. Grant `DATA_PROVIDER_ROLE` on oracle to `LZGovBridgeReceiver`
8. Revoke/transfer `DEFAULT_ADMIN_ROLE` on oracle
9. `setCanCallTarget(forwarder, dstEid, govBridgeReceiver, true)` on sender

## Phase 3: Test end-to-end

10. Call `sUSDS.drip()` then `forwarder.refresh()`
11. Verify oracle values on remote

## Phase 4: Transfer ownership to governance

12. Transfer sender ownership to pause proxy + receiver ownership to L2 governance relay
13. Set endpoint delegate to pause proxy (sender) / L2 governance relay (receiver)
