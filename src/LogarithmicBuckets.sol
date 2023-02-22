// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./BucketDLL.sol";

library LogarithmicBuckets {
    using BucketDLL for BucketDLL.List;

    struct Buckets {
        mapping(uint256 => BucketDLL.List) buckets;
        mapping(address => uint256) valueOf;
        uint256 bucketsMask;
    }

    /// ERRORS ///

    /// @notice Thrown when the address is zero at insertion.
    error ZeroAddress();

    /// @notice Thrown when 0 value is inserted.
    error ZeroValue();

    /// INTERNAL ///

    /// @notice Updates an account in the `_buckets`.
    /// @param _buckets The buckets to update.
    /// @param _id The address of the account.
    /// @param _newValue The new value of the account.
    /// @param _head Indicates whether to insert the new values at the head or at the tail of the buckets list.
    function update(
        Buckets storage _buckets,
        address _id,
        uint256 _newValue,
        bool _head
    ) internal {
        if (_id == address(0)) revert ZeroAddress();
        uint256 value = _buckets.valueOf[_id];
        _buckets.valueOf[_id] = _newValue;

        if (value == 0) {
            if (_newValue == 0) revert ZeroValue();
            _insert(_buckets, _id, computeBucket(_newValue), _head);
            return;
        }

        uint256 currentBucket = computeBucket(value);
        if (_newValue == 0) {
            _remove(_buckets, _id, currentBucket);
            return;
        }

        uint256 newBucket = computeBucket(_newValue);
        if (newBucket != currentBucket) {
            _remove(_buckets, _id, currentBucket);
            _insert(_buckets, _id, newBucket, _head);
        }
    }

    /// @notice Returns the address in `_buckets` that is a candidate for matching the value `_value`.
    /// @param _buckets The buckets to get the head.
    /// @param _value The value to match.
    /// @return The address of the head.
    function getMatch(Buckets storage _buckets, uint256 _value) internal view returns (address) {
        uint256 bucketsMask = _buckets.bucketsMask;
        if (bucketsMask == 0) return address(0);
        uint256 lowerMask = setLowerBits(_value);

        uint256 next = nextBucket(lowerMask, bucketsMask);

        if (next != 0) return _buckets.buckets[next].getHead();

        uint256 prev = highestBucket(bucketsMask);

        return _buckets.buckets[prev].getHead();
    }

    /// PRIVATE ///

    /// @notice Removes an account in the `_buckets`.
    /// @dev Does not update the value.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to remove.
    /// @param _bucket The mask of the bucket where to remove.
    function _remove(
        Buckets storage _buckets,
        address _id,
        uint256 _bucket
    ) private {
        if (_buckets.buckets[_bucket].remove(_id)) _buckets.bucketsMask &= ~_bucket;
    }

    /// @notice Inserts an account in the `_buckets`.
    /// @dev Expects that `_id` != 0.
    /// @dev Does not update the value.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to update.
    /// @param _bucket The mask of the bucket where to insert.
    /// @param _head Whether to insert at the head or at the tail of the list.
    function _insert(
        Buckets storage _buckets,
        address _id,
        uint256 _bucket,
        bool _head
    ) private {
        if (_buckets.buckets[_bucket].insert(_id, _head)) _buckets.bucketsMask |= _bucket;
    }

    /// PURE HELPERS ///

    /// @notice Returns the bucket in which the given value would fall.
    function computeBucket(uint256 _value) internal pure returns (uint256) {
        uint256 lowerMask = setLowerBits(_value);
        return lowerMask ^ (lowerMask >> 1);
    }

    /// @notice Sets all the bits lower than (or equal to) the highest bit in the input.
    /// @dev This is the same as rounding the input the nearest upper value of the form `2 ** n - 1`.
    function setLowerBits(uint256 x) internal pure returns (uint256 y) {
        assembly {
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))
            x := or(x, shr(32, x))
            x := or(x, shr(64, x))
            y := or(x, shr(128, x))
        }
    }

    /// @notice Returns the following non-empty bucket.
    /// @dev The bucket returned is the lowest that is in `bucketsMask` and not in `lowerMask`.
    function nextBucket(uint256 lowerMask, uint256 bucketsMask)
        internal
        pure
        returns (uint256 bucket)
    {
        assembly {
            let higherBucketsMask := and(not(lowerMask), bucketsMask)
            bucket := and(higherBucketsMask, add(not(higherBucketsMask), 1))
        }
    }

    /// @notice Returns the highest non-empty bucket.
    function highestBucket(uint256 bucketsMask) internal pure returns (uint256) {
        uint256 lowerBucketsMask = setLowerBits(bucketsMask);
        return lowerBucketsMask ^ (lowerBucketsMask >> 1);
    }
}
