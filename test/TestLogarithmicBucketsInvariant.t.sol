// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./helpers/Random.sol";
import "./mocks/LogarithmicBucketsMock.sol";
import "./mocks/BucketDLLMock.sol";
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
    function invariantZeroAccountIsNotInserted() public {
        assertEq(buckets.getValueOf(address(0)), 0);
    }

    // Check that if the buckets are not all empty, then matching returns some non zero address.
    function invariantGetMatch() public {
        bool notEmpty = buckets.maxBucket() != 0;
        uint256 value = randomUint256();
        assertTrue(!notEmpty || buckets.getMatch(value) != address(0));
    }
}

contract LogarithmicBucketsSeenMock is LogarithmicBucketsMock {
    using BucketDLLMock for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

    address[] public seen;
    mapping(address => bool) public isSeen;

    function seenLength() public view returns (uint256) {
        return seen.length;
    }

    function update(
        address _id,
        uint256 _newValue,
        bool _head
    ) public override {
        if (!isSeen[_id]) {
            isSeen[_id] = true;
            seen.push(_id);
        }

        super.update(_id, _newValue, _head);
    }

    function getPrev(uint256 _bucket, address _id) public view returns (address) {
        return buckets.buckets[_bucket].getPrev(_id);
    }

    function getNext(uint256 _bucket, address _id) public view returns (address) {
        return buckets.buckets[_bucket].getNext(_id);
    }
}

contract TestLogarithmicBucketsSeenInvariant is Test, Random {
    LogarithmicBucketsSeenMock public buckets;

    function setUp() public {
        buckets = new LogarithmicBucketsSeenMock();
    }

    function invariantNotZeroAccountIsInserted() public {
        for (uint256 i; i < buckets.seenLength(); i++) {
            address user = buckets.seen(i);
            uint256 value = buckets.getValueOf(user);
            if (value != 0) {
                uint256 bucket = LogarithmicBuckets.highestSetBit(value);
                address next = buckets.getNext(bucket, user);
                address prev = buckets.getPrev(bucket, user);
                assertEq(buckets.getNext(bucket, prev), user);
                assertEq(buckets.getPrev(bucket, next), user);
            }
        }
    }
}
