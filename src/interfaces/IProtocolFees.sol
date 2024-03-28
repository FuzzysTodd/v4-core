// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Currency} from "../types/Currency.sol";

interface IProtocolFees {
    /// @notice Thrown when not enough gas is provided to look up the protocol fee
    error ProtocolFeeCannotBeFetched();
    /// @notice Thrown when the call to fetch the protocol fee reverts or returns invalid data.
    error ProtocolFeeControllerCallFailedOrInvalidResult();
    /// @notice Thrown when a pool does not have a dynamic fee.
    error FeeNotDynamic();

    event ProtocolFeeControllerUpdated(address protocolFeeController);

    /// @notice Given a currency address, returns the protocol fees accrued in that currency
    function protocolFeesAccrued(Currency) external view returns (uint256);
}
