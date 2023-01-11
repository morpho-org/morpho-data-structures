// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./helpers/Random.sol";
import "./mocks/LogarithmicBucketsMock.sol";
import "forge-std/Test.sol";

contract TestLogarithmicBucketsInvariant is Test, Random {
    LogarithmicBucketsMock public buckets;

    function setUp() public {
        buckets = new LogarithmicBucketsMock();
    }

    // Check that the structure of the log buckets is preserved.
    function invariantStructure() public {
        assertTrue(buckets.verifyStructure());
    }

    // Check that the address 0 is never inserted in the buckets.
    function invariantZeroNotInserted() public {
        assertEq(buckets.getValueOf(address(0)), 0);
    }

    // Check that if the buckets are not all empty, then matching returns some non zero address.
    function invariantGetMatch() public {
        bool notEmpty = buckets.maxBucket() != 0;
        uint256 value = randomUint256();
        bool fifo = value % 2 == 0;
        assertTrue(!notEmpty || buckets.getMatch(value, fifo) != address(0));
    }
}
