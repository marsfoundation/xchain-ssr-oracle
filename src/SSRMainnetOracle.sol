// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { ISUSDS } from './interfaces/ISUSDS.sol';

import { SSROracleBase, ISSROracle } from './SSROracleBase.sol';

/**
 * @title  SSRMainnetOracle
 * @notice SSR Oracle that sits on the same chain as MCD.
 */
contract SSRMainnetOracle is SSROracleBase {

    ISUSDS public immutable susds;

    constructor(address _susds) {
        susds = ISUSDS(_susds);

        refresh();
    }

    /**
    * @notice Will refresh the local storage with the updated values.
    * @dev    This does not need to be called that frequently as the values provide complete precision if needed.
    *         `refresh()` should be called immediately whenever the `ssr` value changes.
    */
    function refresh() public {
        _setSUSDSData(ISSROracle.SUSDSData({
            ssr: uint96(susds.ssr()),
            chi: uint120(susds.chi()),
            rho: uint40(susds.rho())
        }));
    }

}
