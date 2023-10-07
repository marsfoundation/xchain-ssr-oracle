// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

/**
 * @title  IDSROracle
 * @notice Consolidated DSR reporting along with some convenience functions.
 */
interface IDSROracle {

    struct PotData {
        uint96  dsr;    // Dai Savings Rate in per-second value [ray]
        uint120 chi;    // Last computed conversion rate [ray]
        uint40  rho;    // Last computed timestamp [seconds]
    }

    function getPotData() external view returns (PotData memory);

    function getDSR() external view returns (uint256);

    function getChi() external view returns (uint256);

    function getRho() external view returns (uint256);

    function getAPR() external view returns (uint256);

    function getConversionRate() external view returns (uint256);

    function getConversionRate(uint256 timestamp) external view returns (uint256);

    function getConversionRateBinomialApprox() external view returns (uint256);

    function getConversionRateBinomialApprox(uint256 timestamp) external view returns (uint256);

    function getConversionRateLinearApprox() external view returns (uint256);

    function getConversionRateLinearApprox(uint256 timestamp) external view returns (uint256);

}
