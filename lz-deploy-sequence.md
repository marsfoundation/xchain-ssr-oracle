# LZ SSR Oracle — Deploy Sequence

## Phase 1: Deploy

1. Run `Deploy.s.sol:DeployLZ` (modify if needed, e.g. to set `maxSSR` on the oracle)

## Phase 2: Configure OApps

2. Wire the forwarder (mainnet):
   - `setPeer` with receiver address
   - `setEnforcedOptions` including both `addExecutorLzReceiveOption` and `addExecutorLzComposeOption` (index 0) so the executor calls `lzCompose` after `lzReceive`
3. Configure LZ routing (DVNs, executor, libraries) on both endpoints

## Phase 3: Test end-to-end

4. Call `sUSDS.drip()` then `forwarder.refresh()` on mainnet
5. Verify oracle values on remote (`getSSR`, `getChi`, `getRho`)

## Phase 4: Finalize ownership and delegate

6. Update delegate on mainnet endpoint for the forwarder (`setDelegate`)
7. Update delegate on remote endpoint for the receiver (`setDelegate`)
8. Transfer forwarder ownership on mainnet
9. Transfer receiver ownership on remote

## Notes on upgradeability

- If the oracle admin role is revoked, its `DATA_PROVIDER_ROLE` cannot be changed, meaning a new oracle must be deployed to change its data source.
- Upgrading the forwarder requires replacing all receivers (since `LZComposeReceiver.sourceAuthority` is immutable). If oracle admin is revoked, this also means replacing all oracles.
