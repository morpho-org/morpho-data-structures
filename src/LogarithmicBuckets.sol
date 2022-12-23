// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./DoubleLinkedList.sol";

library LogarithmicBuckets {
    using DoubleLinkedList for DoubleLinkedList.List;

    struct BucketList {
        mapping(uint256 => DoubleLinkedList.List) lists; // All the accounts.
        mapping(address => uint256) indexOf;
        uint256 maxIndex;
    }

    /// CONSTANTS ///

    uint256 private constant LOGBASE = 4;

    /// ERRORS ///

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// INTERNAL ///

    /// @notice Updates an account in the `_buckets`.
    /// @dev Only call this function when `_id` is in the `_buckets` with value `_formerValue` or when `_id` is not in the `_buckets` with `_formerValue` equal to 0.
    function update(
        BucketList storage _buckets,
        address _id,
        uint256 _formerValue,
        uint256 _newValue
    ) internal {
        uint96 formerValue = SafeCast.toUint96(_formerValue);
        uint96 newValue = SafeCast.toUint96(_newValue);

        if (formerValue != newValue) {
            if (formerValue != 0) remove(_buckets, _id);
            if (newValue != 0) insert(_buckets, _id, newValue);
        }
    }

    /// PRIVATE ///

    function insert(
        BucketList storage _buckets,
        address _id,
        uint96 _value
    ) private {
        // `_buckets` cannot contain the 0 address.
        if (_id == address(0)) revert AddressIsZero();
        uint256 bucketIndex = computeBucketIndex(_value);
        _buckets.lists[bucketIndex].insertTail(_id, _value);
        _buckets.indexOf[_id] = bucketIndex;
        if (bucketIndex > _buckets.maxIndex) _buckets.maxIndex = bucketIndex;
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

    // /// @notice Compute the bucket index.
    // /// @param _value The value of the index to compute.
    // function computeBucketIndex(uint96 _value) private pure returns (uint256) {
    //     for (uint256 i = 0; i < 128; i++) {
    //         if (_value < LOGBASE**i) {
    //             return i;
    //         }
    //     }
    //     return 128;
    // }

    /// @notice Compute the bucket index.
    /// @param _value The value of the index to compute.
    function computeBucketIndex(uint96 _value) private pure returns (uint256) {
        return log2(_value) / log2(LOGBASE);
    }

    /// GETTERS ///

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _buckets The buckets to search in.
    /// @param _id The address of the account.
    /// @return value The value of the account.
    function getValueOf(BucketList storage _buckets, address _id) internal view returns (uint256) {
        return _buckets.lists[_buckets.indexOf[_id]].accounts[_id].value;
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

    // Magic

    function log2(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m, 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m, 0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m, 0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m, 0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m, 0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m, 0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m, 0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m, 0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(
                y,
                mul(
                    256,
                    gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)
                )
            )
        }
    }
}
