// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "lib/morpho-utils/src/math/Math.sol";
import "./DoubleLinkedListFIFO.sol";

library LogarithmicBuckets {
    using DoubleLinkedList for DoubleLinkedList.List;

    struct BucketList {
        mapping(uint256 => DoubleLinkedList.List) lists;
        mapping(address => uint256) balanceOf;
        uint256 bucketsMap;
    }

    /// CONSTANTS ///

    uint256 private constant LOG2_LOGBASE = 2;

    /// ERRORS ///

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// @notice Thrown when 0 value is inserted.
    error ZeroValue();

    /// INTERNAL ///

    /// @notice Updates an account in the `_buckets`.
    function update(
        BucketList storage _buckets,
        address _id,
        uint256 _newValue
    ) internal {
        uint256 balance = _buckets.balanceOf[_id];
        _buckets.balanceOf[_id] = _newValue;

        if (balance == 0) {
            // `_buckets` cannot contain the 0 address.
            if (_newValue == 0) revert ZeroValue();
            if (_id == address(0)) revert AddressIsZero();
            insert(_buckets, _id, computeBucket(_newValue));
            return;
        }

        uint256 currentBucket = computeBucket(balance);
        if (_newValue == 0) {
            remove(_buckets, _id, currentBucket);
            return;
        }

        uint256 newBucket = computeBucket(_newValue);
        if (newBucket != currentBucket) {
            remove(_buckets, _id, currentBucket);
            insert(_buckets, _id, newBucket);
        }
    }

    /// PRIVATE ///

    /// @notice Removes an account in the `_buckets`.
    /// @dev Does not update the value.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to remove.
    /// @param _bucket The mask of the bucket where to remove.
    function remove(
        BucketList storage _buckets,
        address _id,
        uint256 _bucket
    ) private {
        if (_buckets.lists[_bucket].remove(_id)) _buckets.bucketsMap &= _bucket ^ type(uint256).max;
    }

    /// @notice Inserts an account in the `_buckets`.
    /// @dev Expects that `_id` != 0 and if `_value` != 0.
    /// @dev Does not update the value.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to update.
    /// @param _bucket The mask of the bucket where to insert.
    function insert(
        BucketList storage _buckets,
        address _id,
        uint256 _bucket
    ) private {
        if (_buckets.lists[_bucket].insert(_id)) _buckets.bucketsMap |= _bucket;
    }

    /// @notice Compute the bucket bucket.
    /// @param _value The value of the bucket to compute.
    function computeBucket(uint256 _value) private pure returns (uint256) {
        return 1 << (Math.log2(_value) / LOG2_LOGBASE);
    }

    /// GETTERS ///

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @param _id The address of the account.
    /// @return value The value of the account.
    function getValueOf(BucketList storage _buckets, address _id) internal view returns (uint256) {
        return _buckets.balanceOf[_id];
    }

    /// @notice Returns the bucket of the bucket linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @param _id The address of the account.
    /// @return bucket The value of the account.
    function getBucketOf(BucketList storage _buckets, address _id) internal view returns (uint256) {
        return Math.log2(_buckets.balanceOf[_id]) / LOG2_LOGBASE;
    }

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @return value The value of the account.
    function getMaxBucket(BucketList storage _buckets) internal view returns (uint256) {
        return Math.log2(_buckets.bucketsMap);
    }

    /// @notice Returns the address at the head of the `_buckets` for matching the value  `_value`.
    /// @param _buckets The buckets to get the head.
    /// @param _value The value to match.
    /// @return The address of the head.
    function getHead(BucketList storage _buckets, uint256 _value) internal view returns (address) {
        uint256 bucket = computeBucket(_value);
        uint256 bucketMap = _buckets.bucketsMap;

        // There is no non-empty bucket.
        if (bucketMap == 0) {
            return _buckets.lists[0].getHead();
        }

        // There is a non-empty bucket higher than `bucket`.
        if (bucketMap >= bucket) {
            while (bucket & bucketMap == 0) {
                bucket <<= 1;
            }
            return _buckets.lists[bucket].getHead();
        }

        // There is a non-empty bucket lower than `bucket`.
        while (bucket & bucketMap == 0) {
            bucket >>= 1;
        }
        return _buckets.lists[bucket].getHead();
    }

    /// @notice Returns the address of the next account in the bucket of _id.
    /// @param _buckets The buckets to get the head.
    /// @param _id current address.
    /// @return The address of the head.
    function getNext(BucketList storage _buckets, address _id) internal view returns (address) {
        uint256 bucket = computeBucket(_buckets.balanceOf[_id]);
        return _buckets.lists[bucket].getNext(_id);
    }
}
