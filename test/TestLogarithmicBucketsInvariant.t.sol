// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./mocks/LogarithmicBucketsMock.sol";
import "forge-std/Test.sol";

contract TestLogarithmicBucketsInvariant is Test {
    LogarithmicBucketsMock public buckets;

    function setUp() public {
        buckets = new LogarithmicBucketsMock();
    }

    struct FuzzSelector {
        address addr;
        bytes4[] selectors;
    }

    // Target specific selectors for invariant testing.
    function targetSelectors() public view returns (FuzzSelector[] memory) {
        FuzzSelector[] memory targets = new FuzzSelector[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = LogarithmicBucketsMock.update.selector;
        targets[0] = FuzzSelector(address(buckets), selectors);
        return targets;
    }

    // Check that the structure of the log buckets is preserved.
    function invariantStructure() public {
        assertTrue(buckets.verifyStructure());
    }
}
