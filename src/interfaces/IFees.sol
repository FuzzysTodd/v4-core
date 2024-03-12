// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Currency} from "../types/Currency.sol";

interface IFees {
    /// @notice Thrown when the protocol fee denominator is less than 4. Also thrown when the static or dynamic fee on a pool is exceeds 100%.
    error FeeTooLarge();
    /// @notice Thrown when not enough gas is provided to look up the protocol fee
    error ProtocolFeeCannotBeFetched();
    /// @notice Thrown when the call to fetch the protocol fee reverts or returns invalid data.
    error ProtocolFeeControllerCallFailedOrInvalidResult();
    /// @notice Thrown when a pool does not have a dynamic fee.
    error FeeNotDynamic();

    event ProtocolFeeControllerUpdated(address protocolFeeController);

    /// @notice Returns the maximum for the protocol fee, which restricts it to a maximum of 25%
    function MAX_PROTOCOL_FEE() external view returns (uint16);

    /// @notice Given a currency address, returns the protocol fees accrued in that currency
    function protocolFeesAccrued(Currency) external view returns (uint256);
}
