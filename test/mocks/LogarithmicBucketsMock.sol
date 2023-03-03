// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/LogarithmicBuckets.sol";
import "./BucketDLLMock.sol";

contract LogarithmicBucketsMock {
    using BucketDLLMock for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

    LogarithmicBuckets.Buckets public buckets;

    function update(
        address _id,
        uint256 _newValue,
        bool _head
    ) public virtual {
        buckets.update(_id, _newValue, _head);
    }

    function getValueOf(address _id) public view returns (uint256) {
        return buckets.valueOf[_id];
    }

    function maxBucket() public view returns (uint256) {
        uint256 lowerMask = LogarithmicBuckets.setLowerBits(buckets.bucketsMask);
        return lowerMask ^ (lowerMask >> 1);
    }

    function getMatch(uint256 _value) public view returns (address) {
        return buckets.getMatch(_value);
    }

    function verifyStructure() public view returns (bool) {
        for (uint256 i; i < 256; i++) {
            uint256 lowerValue = 2**i;
            uint256 higherValue;
            unchecked {
                higherValue = 2**(i + 1) - 1;
            }

            BucketDLL.List storage list = buckets.buckets[lowerValue];

            for (address id = list.getHead(); id != address(0); id = list.getNext(id)) {
                uint256 value = buckets.valueOf[id];
                if (value < lowerValue || value > higherValue) return false;
            }
        }
        return true;
    }

    function nextBucketValue(uint256 _value) internal view returns (uint256) {
        uint256 bucketsMask = buckets.bucketsMask;
        uint256 lowerMask = LogarithmicBuckets.setLowerBits(_value);
        return LogarithmicBuckets.nextBucket(lowerMask, bucketsMask);
    }

    function highestBucketValue() internal view returns (uint256) {
        return LogarithmicBuckets.highestSetBit(buckets.bucketsMask);
    }
}
