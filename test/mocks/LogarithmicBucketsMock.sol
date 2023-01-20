// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/LogarithmicBuckets.sol";

contract LogarithmicBucketsMock {
    using BucketDLL for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    LogarithmicBuckets.BucketList public bucketList;

    function update(
        address _id,
        uint256 _newValue,
        bool _head
    ) public virtual {
        bucketList.update(_id, _newValue, _head);
    }

    function getValueOf(address _id) public view returns (uint256) {
        return bucketList.getValueOf(_id);
    }

    function maxBucket() public view returns (uint256) {
        uint256 lowerMask = LogarithmicBuckets.setLowerBits(bucketList.bucketsMask);
        return lowerMask ^ (lowerMask >> 1);
    }

    function getMatch(uint256 _value) public view returns (address) {
        return bucketList.getMatch(_value);
    }

    function verifyStructure() public view returns (bool) {
        for (uint256 i; i < 256; i++) {
            uint256 lowerValue = 2**i;
            uint256 higherValue;
            unchecked {
                higherValue = 2**(i + 1) - 1;
            }

            BucketDLL.List storage list = bucketList.getBucketOf(lowerValue);

            for (address id = list.getHead(); id != address(0); id = list.getNext(id)) {
                uint256 value = bucketList.getValueOf(id);
                if (value < lowerValue || value > higherValue) return false;
            }
        }
        return true;
    }

    function nextBucket(uint256 _value) internal view returns (uint256) {
        uint256 bucketsMask = bucketList.bucketsMask;
        uint256 lowerMask = LogarithmicBuckets.setLowerBits(_value);
        return LogarithmicBuckets.nextBucket(lowerMask, bucketsMask);
    }

    function prevBucket(uint256 _value) internal view returns (uint256) {
        uint256 bucketsMask = bucketList.bucketsMask;
        uint256 lowerMask = LogarithmicBuckets.setLowerBits(_value);
        return LogarithmicBuckets.prevBucket(lowerMask, bucketsMask);
    }
}
