// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {LogarithmicBuckets} from "src/LogarithmicBuckets.sol";
import {BucketDLLMock, BucketDLL} from "./BucketDLLMock.sol";

contract LogarithmicBucketsMock {
    using BucketDLLMock for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

    /* STORAGE */

    LogarithmicBuckets.Buckets public buckets;

    /* PUBLIC */

    function update(address id, uint256 newValue, bool head) public virtual {
        buckets.update(id, newValue, head);
    }

    function getValueOf(address id) public view returns (uint256) {
        return buckets.valueOf[id];
    }

    function maxBucket() public view returns (uint256) {
        uint256 lowerMask = LogarithmicBuckets.setLowerBits(buckets.bucketsMask);
        return lowerMask ^ (lowerMask >> 1);
    }

    function getMatch(uint256 value) public view returns (address) {
        return buckets.getMatch(value);
    }

    function verifyStructure() public view returns (bool) {
        for (uint256 i; i < 256; i++) {
            uint256 lowerValue = 2 ** i;
            uint256 higherValue;
            unchecked {
                higherValue = 2 ** (i + 1) - 1;
            }

            BucketDLL.List storage list = buckets.buckets[lowerValue];

            for (address id = list.getHead(); id != address(0); id = list.getNext(id)) {
                uint256 value = buckets.valueOf[id];
                if (value < lowerValue || value > higherValue) return false;
            }
        }
        return true;
    }

    /* INTERNAL*/

    function nextBucketValue(uint256 value) internal view returns (uint256) {
        uint256 bucketsMask = buckets.bucketsMask;
        uint256 lowerMask = LogarithmicBuckets.setLowerBits(value);
        return LogarithmicBuckets.nextBucket(lowerMask, bucketsMask);
    }

    function highestBucketValue() internal view returns (uint256) {
        return LogarithmicBuckets.highestSetBit(buckets.bucketsMask);
    }
}
