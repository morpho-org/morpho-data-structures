// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "lib/morpho-utils/src/math/Math.sol";
import "./DoubleLinkedListFIFO.sol";

library LogarithmicBuckets {
    using DoubleLinkedList for DoubleLinkedList.List;

    struct BucketList {
        mapping(uint256 => DoubleLinkedList.List) lists; // All the accounts.
        mapping(address => uint256) balanceOf;
        uint256 maxBucket;
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

        if (balance != 0) {
            uint256 currentBucket = computeBucketOf(balance);
            _buckets.balanceOf[_id] = _newValue;

            if (_newValue == 0) {
                remove(_buckets, _id, currentBucket);
                return;
            }

            uint256 newBucket = computeBucketOf(_newValue);
            if (newBucket == currentBucket) {
                return;
            }

            remove(_buckets, _id, currentBucket);
            insert(_buckets, _id, newBucket);
            return;
        }

        // `_buckets` cannot contain the 0 address.
        if (_id == address(0)) revert AddressIsZero();
        if (_newValue == 0) revert ZeroValue();
        _buckets.balanceOf[_id] = _newValue;
        insert(_buckets, _id, computeBucketOf(_newValue));
    }

    /// PRIVATE ///

    /// @notice Removes an account in the `_buckets`.
    /// @dev Does not update the value.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to remove.
    function remove(
        BucketList storage _buckets,
        address _id,
        uint256 _bucket
    ) private {
        uint256 maxBucket = _buckets.maxBucket;

        // Revert if `_id` does not exist.
        _buckets.lists[_bucket].remove(_id);

        if (_bucket == maxBucket) {
            while (_buckets.lists[_bucket].getHead() == address(0) && _bucket > 0) {
                // Safe unchecked because bucket > 0.
                unchecked {
                    --_bucket;
                }
            }
            if (_bucket != maxBucket) _buckets.maxBucket = _bucket;
        }
    }

    /// @notice Inserts an account in the `_buckets`.
    /// @dev Expects that `_id` != 0 and if `_value` != 0.
    /// @dev Does not update the value.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to update.
    /// @param _newBucket The bucket where to insert
    function insert(
        BucketList storage _buckets,
        address _id,
        uint256 _newBucket
    ) private {
        _buckets.lists[_newBucket].insert(_id);
        if (_newBucket > _buckets.maxBucket) _buckets.maxBucket = _newBucket;
    }

    /// @notice Compute the bucket bucket.
    /// @param _value The value of the bucket to compute.
    function computeBucketOf(uint256 _value) private pure returns (uint256) {
        return Math.log2(_value) / LOG2_LOGBASE;
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
        return computeBucketOf(_buckets.balanceOf[_id]);
    }

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @return value The value of the account.
    function getMaxBucket(BucketList storage _buckets) internal view returns (uint256) {
        return _buckets.maxBucket;
    }

    /// @notice Returns the address at the head of the `_buckets` for matching the value  `_value`.
    /// @param _buckets The buckets to get the head.
    /// @param _value The value to match.
    /// @return The address of the head.
    function getHead(BucketList storage _buckets, uint256 _value) internal view returns (address) {
        uint256 bucket = computeBucketOf(_value);
        uint256 maxBucket = _buckets.maxBucket;

        if (bucket < maxBucket) {
            address head;
            while ((head = _buckets.lists[bucket].getHead()) == address(0)) {
                // Safe unchecked because bucket <= maxBucket.
                unchecked {
                    ++bucket;
                }
            }
            return head;
        }
        return _buckets.lists[maxBucket].getHead();
    }

    /// @notice Returns the address of the next account in the bucket of _id.
    /// @param _buckets The buckets to get the head.
    /// @param _id current address.
    /// @return The address of the head.
    function getNext(BucketList storage _buckets, address _id) internal view returns (address) {
        uint256 bucket = getBucketOf(_buckets, _id);
        return _buckets.lists[bucket].accounts[_id].next;
    }
}
