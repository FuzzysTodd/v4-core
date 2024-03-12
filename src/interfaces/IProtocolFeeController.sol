// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PoolKey} from "../types/PoolKey.sol";

interface IProtocolFeeController {
    /// @notice Returns the protocol fees for a pool given the conditions of this contract
    /// @param poolKey The pool key to identify the pool. The controller may want to use attributes on the pool
    ///   to determine the protocol fee, hence the entire key is needed.
    function protocolFeeForPool(PoolKey memory poolKey) external view returns (uint32);
}
