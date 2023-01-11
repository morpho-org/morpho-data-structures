// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/LogarithmicBuckets.sol";
import "forge-std/Test.sol";

contract LogarithmicBucketsMock is Test {
    using BucketDLL for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    LogarithmicBuckets.BucketList public bucketList;

    function update(address _id, uint256 _newValue) public {
        bucketList.update(_id, _newValue);
    }

    function verifyStructure() public {
        for (uint256 i; i < 256; i++) {
            uint256 lowerValue = 2**i;
            uint256 higherValue;
            unchecked {
                higherValue = 2**(i + 1) - 1;
            }

            BucketDLL.List storage list = bucketList.getBucketOf(lowerValue);

            for (address id = list.getHead(); id != address(0); id = list.getNext(id)) {
                uint256 value = bucketList.getValueOf(id);
                assertTrue(
                    lowerValue <= value,
                    string.concat(
                        vm.toString(lowerValue),
                        string.concat(" should be lower than ", vm.toString(value))
                    )
                );
                assertTrue(
                    value <= higherValue,
                    string.concat(
                        vm.toString(value),
                        string.concat(" should be lower than ", vm.toString(higherValue))
                    )
                );
            }
        }
    }
}
