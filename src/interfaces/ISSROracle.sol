// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

/**
 * @title  ISSROracle
 * @notice Consolidated SSR reporting along with some convenience functions.
 */
interface ISSROracle {

    struct PotData {
        uint96  ssr;  // Sky Savings Rate in per-second value [ray]
        uint120 chi;  // Last computed conversion rate [ray]
        uint40  rho;  // Last computed timestamp [seconds]
    }

    /**
     * @notice Emitted when the PotData is updated.
     * @param  nextData The new PotData struct.
     */
    event SetPotData(PotData nextData);

    /**
     * @notice Retrieve the current PotData: ssr, chi, and rho.
     * @return The current PotData struct.
     */
    function getPotData() external view returns (PotData memory);

    /**
     * @notice Get the current Sky Savings Rate.
     * @return The Sky Savings Rate in per-second value [ray].
     */
    function getSSR() external view returns (uint256);

    /**
     * @notice Get the last computed conversion rate.
     * @return The last computed conversion rate [ray].
     */
    function getChi() external view returns (uint256);

    /**
     * @notice Get the last computed timestamp.
     * @return The last computed timestamp [seconds].
     */
    function getRho() external view returns (uint256);

    /**
     * @notice Get the Annual Percentage Rate.
     * @return The APR.
     */
    function getAPR() external view returns (uint256);

    /**
     * @notice Get the conversion rate at the current timestamp.
     * @return The conversion rate.
     */
    function getConversionRate() external view returns (uint256);

    /**
     * @notice Get the conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the conversion rate.
     * @return The conversion rate.
     */
    function getConversionRate(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the binomial approximated conversion rate at the current timestamp.
     * @return The binomial approximated conversion rate.
     */
    function getConversionRateBinomialApprox() external view returns (uint256);

    /**
     * @notice Get the binomial approximated conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the binomial approximated conversion rate.
     * @return The binomial approximated conversion rate.
     */
    function getConversionRateBinomialApprox(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the linear approximated conversion rate at the current timestamp.
     * @return The linear approximated conversion rate.
     */
    function getConversionRateLinearApprox() external view returns (uint256);

    /**
     * @notice Get the linear approximated conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the linear approximated conversion rate.
     * @return The linear approximated conversion rate.
     */
    function getConversionRateLinearApprox(uint256 timestamp) external view returns (uint256);

}
