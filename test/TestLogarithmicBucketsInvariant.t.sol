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
    function invariantGetMatchFIFO() public {
        bool notEmpty = buckets.maxBucket() != 0;
        uint256 value = randomUint256();
        assertTrue(!notEmpty || buckets.getMatch(value, true) != address(0));
    }

    function invariantGetMatchLIFO() public {
        bool notEmpty = buckets.maxBucket() != 0;
        uint256 value = randomUint256();
        assertTrue(!notEmpty || buckets.getMatch(value, false) != address(0));
    }
}

contract LogarithmicBucketsSeenMock is LogarithmicBucketsMock {
    using BucketDLL for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    address[] public seen;
    mapping(address => bool) public isSeen;

    function seenLength() public view returns (uint256) {
        return seen.length;
    }

    function update(address _id, uint256 _newValue) public override {
        if (!isSeen[_id]) {
            isSeen[_id] = true;
            seen.push(_id);
        }

        super.update(_id, _newValue);
    }

    function getPrev(uint256 _value, address _id) public view returns (address) {
        BucketDLL.List storage bucket = bucketList.getBucketOf(_value);
        return bucket.getPrev(_id);
    }

    function getNext(uint256 _value, address _id) public view returns (address) {
        BucketDLL.List storage bucket = bucketList.getBucketOf(_value);
        return bucket.getNext(_id);
    }
}

contract TestLogarithmicBucketsSeenInvariant is Test, Random {
    LogarithmicBucketsSeenMock public buckets;

    function setUp() public {
        buckets = new LogarithmicBucketsSeenMock();
    }

    function invariantNotZeroInserted() public {
        for (uint256 i; i < buckets.seenLength(); i++) {
            address user = buckets.seen(i);
            uint256 value = buckets.getValueOf(user);
            if (value != 0) {
                address next = buckets.getNext(value, user);
                address prev = buckets.getPrev(value, user);
                assertEq(buckets.getNext(value, prev), user);
                assertEq(buckets.getPrev(value, next), user);
            }
        }
    }
}
