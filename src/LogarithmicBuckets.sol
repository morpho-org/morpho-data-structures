// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "lib/morpho-utils/src/math/Math.sol";
import "./DoubleLinkedList.sol";

library LogarithmicBuckets {
    using DoubleLinkedList for DoubleLinkedList.List;

    struct BucketList {
        mapping(uint256 => DoubleLinkedList.List) lists; // All the accounts.
        mapping(address => uint256) indexOf;
        uint256 maxIndex;
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
    /// @dev Only call this function when `_id` is in the `_buckets` with value `_formerValue` or when `_id` is not in the `_buckets` with `_formerValue` equal to 0.
    function update(
        BucketList storage _buckets,
        address _id,
        uint256 _newValue
    ) internal {
        uint256 formerValue256 = getValueOf(_buckets, _id);
        uint96 formerValue = SafeCast.toUint96(formerValue256);
        uint96 newValue = SafeCast.toUint96(_newValue);
        uint256 newBucketIndex;

        if (formerValue != 0 && newValue == 0) {
            remove(_buckets, _id);
        } else if (
            (newBucketIndex = computeBucketIndex(newValue)) == getBucketOf(_buckets, _id) &&
            formerValue != 0
        ) {
            update_value(_buckets, _id, newValue);
        } else if (formerValue != newValue) {
            if (formerValue != 0) remove(_buckets, _id);
            insert(_buckets, _id, newValue, newBucketIndex);
        }
    }

    /// PRIVATE ///

    /// @notice Removes an account in the `_buckets`.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to update.
    /// @param _value The new value.
    function update_value(
        BucketList storage _buckets,
        address _id,
        uint96 _value
    ) private {
        uint256 index = _buckets.indexOf[_id];
        // Revert if `_id` does not exist.
        _buckets.lists[index].accounts[_id].value = _value;
    }

    /// @notice Removes an account in the `_buckets`.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to remove.
    function remove(BucketList storage _buckets, address _id) private {
        uint256 index = _buckets.indexOf[_id];
        // Revert if `_id` does not exist.
        _buckets.lists[index].remove(_id);
        delete _buckets.indexOf[_id];

        if (index == _buckets.maxIndex) {
            while (_buckets.lists[index].head == address(0) && index > 0) {
                index -= 1;
            }
            _buckets.maxIndex = index;
        }
    }

    /// @notice Removes an account in the `_buckets`.
    /// @param _buckets The buckets to modify.
    /// @param _id The address of the account to update.
    /// @param _value The new value.
    function insert(
        BucketList storage _buckets,
        address _id,
        uint96 _value,
        uint256 _newBucketIndex
    ) private {
        // `_buckets` cannot contain the 0 address.
        if (_id == address(0)) revert AddressIsZero();
        if (_value == 0) revert ZeroValue();
        uint256 bucketIndex = _newBucketIndex;
        _buckets.lists[bucketIndex].insertTail(_id, _value);
        _buckets.indexOf[_id] = bucketIndex;
        if (bucketIndex > _buckets.maxIndex) _buckets.maxIndex = bucketIndex;
    }

    /// @notice Compute the bucket index.
    /// @param _value The value of the index to compute.
    function computeBucketIndex(uint96 _value) private pure returns (uint256) {
        return Math.log2(_value) / LOG2_LOGBASE;
    }

    /// GETTERS ///

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @param _id The address of the account.
    /// @return value The value of the account.
    function getValueOf(BucketList storage _buckets, address _id) internal view returns (uint256) {
        return _buckets.lists[_buckets.indexOf[_id]].accounts[_id].value;
    }

    /// @notice Returns the index of the bucket linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @param _id The address of the account.
    /// @return index The value of the account.
    function getBucketOf(BucketList storage _buckets, address _id) internal view returns (uint256) {
        return _buckets.indexOf[_id];
    }

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @return value The value of the account.
    function getMaxIndex(BucketList storage _buckets) internal view returns (uint256) {
        return _buckets.maxIndex;
    }

    /// @notice Returns the address at the head of the `_buckets` for matching the value  `_value`.
    /// @param _buckets The buckets to get the head.
    /// @param _value The value to match.
    /// @return The address of the head.
    function getHead(BucketList storage _buckets, uint96 _value) internal view returns (address) {
        uint256 index = computeBucketIndex(_value);
        address head = _buckets.lists[index].head;

        if (_buckets.maxIndex == 0) {
            head = _buckets.lists[0].head;
        } else if (index <= _buckets.maxIndex) {
            while (head == address(0)) {
                index += 1;
                head = _buckets.lists[index].head;
            }
        } else {
            index = _buckets.maxIndex + 1;
            while (head == address(0)) {
                index -= 1;
                head = _buckets.lists[index].head;
            }
        }
        return head;
    }

    /// @notice Returns the address of the next account in the bucket of _id.
    /// @param _buckets The buckets to get the head.
    /// @param _id current address.
    /// @return The address of the head.
    function getNext(BucketList storage _buckets, address _id) internal view returns (address) {
        uint256 bucketIndex = getBucketOf(_buckets, _id);
        return _buckets.lists[bucketIndex].accounts[_id].next;
    }
}
