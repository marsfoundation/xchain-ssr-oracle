deploy-optimism :; forge script script/Deploy.s.sol:DeployOptimism --sender ${ETH_FROM} --broadcast --verify
deploy-base     :; forge script script/Deploy.s.sol:DeployBase --sender ${ETH_FROM} --broadcast --verify
deploy-gnosis   :; ORACLE_ADMIN=0xc4218C1127cB24a0D6c1e7D25dc34e10f2625f5A forge script script/Deploy.s.sol:DeployGnosis --sender ${ETH_FROM} --broadcast --verify
