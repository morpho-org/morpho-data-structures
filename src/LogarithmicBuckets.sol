// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./BucketDLL.sol";

/// @title LogarithmicBuckets
/// @author Morpho Labs
/// @custom:contact security@morpho.xyz
/// @notice The logarithmic buckets data-structure.
library LogarithmicBuckets {
    using BucketDLL for BucketDLL.List;

    struct Buckets {
        mapping(uint256 => BucketDLL.List) buckets;
        mapping(address => uint256) valueOf;
        uint256 bucketsMask;
    }

    /* ERRORS */

    /// @notice Thrown when the address is zero at insertion.
    error ZeroAddress();

    /// @notice Thrown when 0 value is inserted.
    error ZeroValue();

    /* INTERNAL */

    /// @notice Updates an account in the `buckets`.
    /// @param buckets The buckets to update.
    /// @param id The address of the account.
    /// @param newValue The new value of the account.
    /// @param head Indicates whether to insert the new values at the head or at the tail of the buckets list.
    function update(
        Buckets storage buckets,
        address id,
        uint256 newValue,
        bool head
    ) internal {
        if (id == address(0)) revert ZeroAddress();
        uint256 value = buckets.valueOf[id];
        buckets.valueOf[id] = newValue;

        if (value == 0) {
            if (newValue == 0) revert ZeroValue();
            // `highestSetBit` is used to compute the bucket associated with `newValue`.
            _insert(buckets, id, highestSetBit(newValue), head);
            return;
        }

        // `highestSetBit` is used to compute the bucket associated with `value`.
        uint256 currentBucket = highestSetBit(value);
        if (newValue == 0) {
            _remove(buckets, id, currentBucket);
            return;
        }

        // `highestSetBit` is used to compute the bucket associated with `newValue`.
        uint256 newBucket = highestSetBit(newValue);
        if (newBucket != currentBucket) {
            _remove(buckets, id, currentBucket);
            _insert(buckets, id, newBucket, head);
        }
    }

    /// @notice Returns the address in `buckets` that is a candidate for matching the value `value`.
    /// @param buckets The buckets to get the head.
    /// @param value The value to match.
    /// @return The address of the head.
    function getMatch(Buckets storage buckets, uint256 value) internal view returns (address) {
        uint256 bucketsMask = buckets.bucketsMask;
        if (bucketsMask == 0) return address(0);

        uint256 next = nextBucket(value, bucketsMask);
        if (next != 0) return buckets.buckets[next].getNext(address(0));

        // `highestSetBit` is used to compute the highest non-empty bucket.
        // Knowing that `next` == 0, it is also the highest previous non-empty bucket.
        uint256 prev = highestSetBit(bucketsMask);
        return buckets.buckets[prev].getNext(address(0));
    }

    /* PRIVATE */

    /// @notice Removes an account in the `buckets`.
    /// @dev Does not update the value.
    /// @param buckets The buckets to modify.
    /// @param id The address of the account to remove.
    /// @param bucket The mask of the bucket where to remove.
    function _remove(
        Buckets storage buckets,
        address id,
        uint256 bucket
    ) private {
        if (buckets.buckets[bucket].remove(id)) buckets.bucketsMask &= ~bucket;
    }

    /// @notice Inserts an account in the `buckets`.
    /// @dev Expects that `id` != 0.
    /// @dev Does not update the value.
    /// @param buckets The buckets to modify.
    /// @param id The address of the account to update.
    /// @param bucket The mask of the bucket where to insert.
    /// @param head Whether to insert at the head or at the tail of the list.
    function _insert(
        Buckets storage buckets,
        address id,
        uint256 bucket,
        bool head
    ) private {
        if (buckets.buckets[bucket].insert(id, head)) buckets.bucketsMask |= bucket;
    }

    /* PURE HELPERS */

    /// @notice Returns the highest set bit.
    /// @dev Used to compute the bucket associated to a given `value`.
    /// @dev Used to compute the highest non empty bucket given the `bucketsMask`.
    function highestSetBit(uint256 value) internal pure returns (uint256) {
        uint256 lowerMask = setLowerBits(value);
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

    /// @notice Returns the lowest non-empty bucket containing larger values.
    /// @dev The bucket returned is the lowest that is in `bucketsMask` and not in `lowerMask`.
    function nextBucket(uint256 value, uint256 bucketsMask) internal pure returns (uint256 bucket) {
        uint256 lowerMask = setLowerBits(value);
        assembly {
            let higherBucketsMask := and(not(lowerMask), bucketsMask)
            bucket := and(higherBucketsMask, add(not(higherBucketsMask), 1))
        }
    }
}
