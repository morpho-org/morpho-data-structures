// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/BucketDLL.sol";
import "src/LogarithmicBuckets.sol";

contract LogarithmicBucketsMock {
    using BucketDLL for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    LogarithmicBuckets.BucketList public bucketList;

    function update(address _id, uint256 _newValue) public {
        bucketList.update(_id, _newValue);
    }

    function verifyStructure() public view returns (bool) {
        for (uint256 i; i < 256; i++) {
            uint256 lowerValue = 2**i;
            uint256 higherValue;
            if (i == 255) higherValue = type(uint256).max;
            else higherValue = 2**(i + 1) - 1;

            BucketDLL.List storage list = bucketList.getBucketOf(lowerValue);

            for (address id = list.getHead(); id != address(0); id = list.getNext(id)) {
                uint256 value = bucketList.getValueOf(id);
                if (value < lowerValue || value > higherValue) return false;
            }
        }
        return true;
    }
}
