// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {SafeCast} from "../lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

/// @title Heap Ordering.
/// @author Morpho Labs.
/// @custom:contact security@morpho.xyz
/// @notice Modified implementation of a Heap with capped sorting insertion.
library HeapOrdering {
    /* STRUCTS */

    struct Account {
        address id; // The address of the account.
        uint96 value; // The value of the account.
    }

    struct HeapArray {
        Account[] accounts; // All the accounts.
        uint256 size; // The size of the heap portion of the structure, should be less than accounts length, the rest is an unordered array.
        mapping(address => uint256) indexOf; // A mapping from an address to an index in accounts. From index i, the parent index is (i-1)/2, the left child index is 2*i+1 and the right child index is 2*i+2.
    }

    /* CONSTANTS */

    uint256 private constant _ROOT = 0;

    /* ERRORS */

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /* INTERNAL */

    /// @notice Returns the number of users in the `heap`.
    /// @param heap The heap parameter.
    /// @return The length of the heap.
    function length(HeapArray storage heap) internal view returns (uint256) {
        return heap.accounts.length;
    }

    /// @notice Returns the value of the account linked to `id`.
    /// @param heap The heap to search in.
    /// @param id The address of the account.
    /// @return The value of the account.
    function getValueOf(HeapArray storage heap, address id) internal view returns (uint256) {
        uint256 index = heap.indexOf[id];
        if (index >= heap.accounts.length) return 0;
        Account memory account = heap.accounts[index];
        if (account.id != id) return 0;
        else return account.value;
    }

    /// @notice Returns the address at the head of the `heap`.
    /// @param heap The heap to get the head.
    /// @return The address of the head.
    function getHead(HeapArray storage heap) internal view returns (address) {
        if (heap.accounts.length > 0) return heap.accounts[_ROOT].id;
        else return address(0);
    }

    /// @notice Returns the address at the tail of unsorted portion of the `heap`.
    /// @param heap The heap to get the tail.
    /// @return The address of the tail.
    function getTail(HeapArray storage heap) internal view returns (address) {
        uint256 accountsLength = heap.accounts.length;
        if (accountsLength > 0) return heap.accounts[accountsLength - 1].id;
        else return address(0);
    }

    /// @notice Returns the address coming before `id` in accounts.
    /// @dev The account associated to the returned address does not necessarily have a lower value than the one of the account associated to `id`.
    /// @param heap The heap to search in.
    /// @param id The address of the account.
    /// @return The address of the previous account.
    function getPrev(HeapArray storage heap, address id) internal view returns (address) {
        uint256 index = heap.indexOf[id];
        if (index > _ROOT) return heap.accounts[index - 1].id;
        else return address(0);
    }

    /// @notice Returns the address coming after `id` in accounts.
    /// @dev The account associated to the returned address does not necessarily have a greater value than the one of the account associated to `id`.
    /// @param heap The heap to search in.
    /// @param id The address of the account.
    /// @return The address of the next account.
    function getNext(HeapArray storage heap, address id) internal view returns (address) {
        uint256 index = heap.indexOf[id];
        if (index + 1 >= heap.accounts.length || heap.accounts[index].id != id) {
            return address(0);
        } else {
            return heap.accounts[index + 1].id;
        }
    }

    /// @notice Updates an account in the `heap`.
    /// @dev Only call this function when `id` is in the `heap` with value `formerValue` or when `id` is not in the `heap` with `formerValue` equal to 0.
    /// @param heap The heap to modify.
    /// @param id The address of the account to update.
    /// @param formerValue The former value of the account to update.
    /// @param newValue The new value of the account to update.
    /// @param maxSortedUsers The maximum size of the heap.
    function update(HeapArray storage heap, address id, uint256 formerValue, uint256 newValue, uint256 maxSortedUsers)
        internal
    {
        uint96 formerValueCast96 = SafeCast.toUint96(formerValue);
        uint96 newValueCast96 = SafeCast.toUint96(newValue);

        uint256 size = heap.size;
        uint256 newSize = _computeSize(size, maxSortedUsers);
        if (size != newSize) heap.size = newSize;

        if (formerValue != newValue) {
            if (newValue == 0) {
                _remove(heap, newSize, id, formerValueCast96);
            } else if (formerValue == 0) {
                _insert(heap, newSize, id, newValueCast96, maxSortedUsers);
            } else if (formerValue < newValue) {
                _increase(heap, newSize, id, newValueCast96, maxSortedUsers);
            } else {
                _decrease(heap, newSize, id, newValueCast96);
            }
        }
    }

    /* PRIVATE */

    /// @notice Computes a new suitable size for the Heap from `size` that is smaller than `maxSortedUsers`.
    /// @notice Computing the size this way is meant to avoid having all the liquidity in the same path.
    /// @dev We divide by 2 the size to remove the leaves of the heap.
    /// @param size The old size of the heap.
    /// @param maxSortedUsers The maximum size of the heap.
    /// @return The new size computed.
    function _computeSize(uint256 size, uint256 maxSortedUsers) private pure returns (uint256) {
        while (size >= maxSortedUsers) size >>= 1;
        return size;
    }

    /// @notice Sets `index` in the `heap` to be `account`.
    /// @dev The heap may lose its invariant about the order of the values stored.
    /// @dev Only call this function with an index within array's bounds.
    /// @param heap The heap to modify.
    /// @param account The account to set the `index` to.
    /// @param index The index of the account in the heap to be set.

    function _setAccount(HeapArray storage heap, Account memory account, uint256 index) private {
        heap.accounts[index] = account;
        heap.indexOf[account.id] = index;
    }

    /// @notice Moves an account up the heap until its value is smaller than the one of its parent.
    /// @dev This functions restores the invariant about the order of the values stored when the account to move is the only one with value greater than what it should be.
    /// @param heap The heap to modify.
    /// @param accountToShift The account to move.
    /// @param index The index of the account to move.
    function _shiftUp(HeapArray storage heap, Account memory accountToShift, uint256 index) private {
        uint256 valueToShift = accountToShift.value;
        Account memory parentAccount;
        uint256 parentIndex;

        unchecked {
            // index is checked to be greater than 0 before subtracting 1
            while (
                index > _ROOT && valueToShift > (parentAccount = heap.accounts[parentIndex = (index - 1) >> 1]).value
            ) {
                _setAccount(heap, parentAccount, index);
                index = parentIndex;
            }
        }

        _setAccount(heap, accountToShift, index);
    }

    /// @notice Moves an account down the heap until its value is greater than the ones of its children.
    /// @dev This functions restores the invariant about the order of the values stored when the account to move is the only one with value smaller than what it should be.
    /// @param heap The heap to modify.
    /// @param size The computed size of the heap.
    /// @param accountToShift The account to move.
    /// @param index The index of the account to move.
    function _shiftDown(HeapArray storage heap, uint256 size, Account memory accountToShift, uint256 index) private {
        uint256 valueToShift = accountToShift.value;
        uint256 childIndex = (index << 1) + 1;
        uint256 rightChildIndex;
        // At this point, childIndex (resp. childIndex+1) is the index of the left (resp. right) child.

        while (childIndex < size) {
            Account memory childToSwap = heap.accounts[childIndex];

            // Find the child with largest value.
            unchecked {
                rightChildIndex = childIndex + 1; // This cannot overflow because childIndex < size.
            }
            if (rightChildIndex < size) {
                Account memory rightChild = heap.accounts[rightChildIndex];
                if (rightChild.value > childToSwap.value) {
                    childToSwap = rightChild;
                    childIndex = rightChildIndex;
                }
            }

            if (childToSwap.value > valueToShift) {
                _setAccount(heap, childToSwap, index);
                index = childIndex;
                childIndex = (childIndex << 1) + 1;
            } else {
                break;
            }
        }

        _setAccount(heap, accountToShift, index);
    }

    /// @notice Inserts an account in the `heap`.
    /// @dev Only call this function when `id` is not in the `heap`.
    /// @dev Reverts with AddressIsZero if `value` is 0.
    /// @param heap The heap to modify.
    /// @param size The computed size of the heap.
    /// @param id The address of the account to insert.
    /// @param value The value of the account to insert.
    /// @param maxSortedUsers The maximum size of the heap.
    function _insert(HeapArray storage heap, uint256 size, address id, uint96 value, uint256 maxSortedUsers) private {
        // `heap` cannot contain the 0 address.
        if (id == address(0)) revert AddressIsZero();

        uint256 accountsLength = heap.accounts.length;

        heap.accounts.push();

        if (size != accountsLength) _setAccount(heap, heap.accounts[size], accountsLength);

        _shiftUp(heap, Account(id, value), size);
        heap.size = _computeSize(size + 1, maxSortedUsers);
    }

    /// @notice Decreases the amount of an account in the `heap`.
    /// @dev Only call this function when `id` is in the `heap` with a value greater than `newValue`.
    /// @param heap The heap to modify.
    /// @param size The computed size of the heap.
    /// @param id The address of the account to decrease the amount.
    /// @param newValue The new value of the account.
    function _decrease(HeapArray storage heap, uint256 size, address id, uint96 newValue) private {
        uint256 index = heap.indexOf[id];

        // We only need to take care of sorting if there are nodes below in the heap.
        if (index < size >> 1) _shiftDown(heap, size, Account(id, newValue), index);
        else heap.accounts[index].value = newValue;
    }

    /// @notice Increases the amount of an account in the `heap`.
    /// @dev Only call this function when `id` is in the `heap` with a smaller value than `newValue`.
    /// @param heap The heap to modify.
    /// @param size The computed size of the heap.
    /// @param id The address of the account to increase the amount.
    /// @param newValue The new value of the account.
    /// @param maxSortedUsers The maximum size of the heap.
    function _increase(HeapArray storage heap, uint256 size, address id, uint96 newValue, uint256 maxSortedUsers)
        private
    {
        uint256 index = heap.indexOf[id];

        if (index < size) {
            _shiftUp(heap, Account(id, newValue), index);
        } else {
            _setAccount(heap, heap.accounts[size], index);
            _shiftUp(heap, Account(id, newValue), size);
            heap.size = _computeSize(size + 1, maxSortedUsers);
        }
    }

    /// @notice Removes an account in the `heap`.
    /// @dev Only call when this function `id` is in the `heap` with value `removedValue`.
    /// @param heap The heap to modify.
    /// @param size The computed size of the heap.
    /// @param id The address of the account to remove.
    /// @param removedValue The value of the account to remove.
    function _remove(HeapArray storage heap, uint256 size, address id, uint96 removedValue) private {
        uint256 index = heap.indexOf[id];
        delete heap.indexOf[id];
        uint256 accountsLength = heap.accounts.length;

        if (size == accountsLength) heap.size = --size;
        if (index == accountsLength - 1) {
            heap.accounts.pop();
            return;
        }

        Account memory lastAccount = heap.accounts[accountsLength - 1];
        heap.accounts.pop();

        // If the removed account was in the heap, restore the invariant.
        if (index < size) {
            if (removedValue > lastAccount.value) _shiftDown(heap, size, lastAccount, index);
            else _shiftUp(heap, lastAccount, index);
        } else {
            _setAccount(heap, lastAccount, index);
        }
    }
}
