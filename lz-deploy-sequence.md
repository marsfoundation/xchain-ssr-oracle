# LZ SSR Oracle — Deploy Sequence

## Phase 1: Deploy

1. Run `Deploy.s.sol:DeployLZ` (modify if needed, e.g. to set `maxSSR` on the oracle)

## Phase 2: Configure OApps

2. Wire the forwarder (mainnet) (setPeer with receiver address and setEnforcedOptions)
3. Configure LZ routing (DVNs, executor, libraries) on both endpoints

## Phase 3: Test end-to-end

4. Call `sUSDS.drip()` then `forwarder.refresh()` on mainnet
5. Verify oracle values on remote (`getSSR`, `getChi`, `getRho`)

## Phase 4: Finalize ownership and delegate

6. Update delegate on mainnet endpoint for the forwarder (`setDelegate`)
7. Update delegate on remote endpoint for the receiver (`setDelegate`)
8. Transfer forwarder ownership on mainnet
9. Transfer receiver ownership on remote
