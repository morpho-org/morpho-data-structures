// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Heap.
/// @author Morpho Labs.
/// @custom:contact security@morpho.xyz
/// @notice Standard implementation of a heap library.
library BasicHeap {
    /* STRUCTS */

    struct Account {
        address id; // The address of the account.
        uint256 value; // The value of the account.
    }

    struct Heap {
        Account[] accounts; // All the accounts.
        mapping(address => uint256) indexOf; // A mapping from an address to an index in accounts. From index i, the parent index is (i-1)/2, the left child index is 2*i+1 and the right child index is 2*i+2.
    }

    /* CONSTANTS */

    uint256 private constant _ROOT = 0;

    /* ERRORS */

    /// @notice Thrown when trying to modify an account with a wrong value.
    error WrongValue();

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// @notice Thrown when the account is already inserted in the heap.
    error AccountAlreadyInserted();

    /// @notice Thrown when the account to modify does not exist.
    error AccountDoesNotExist();

    /* INTERNAL */

    /// @notice Returns the number of users in the `heap`.
    /// @param heap The heap parameter.
    /// @return The length of the heap.
    function length(Heap storage heap) internal view returns (uint256) {
        return heap.accounts.length;
    }

    /// @notice Checks if the account with the given address `id` exists in the `heap`.
    /// @param heap The heap to search in.
    /// @param id The address of the account to search for.
    /// @return True if the account exists in the heap, false otherwise.
    function containsAccount(Heap storage heap, address id) internal view returns (bool) {
        return _containsAccount(heap, heap.indexOf[id], heap.accounts.length, id);
    }

    /// @notice Returns the value of the account linked to `id`.
    /// @param heap The heap to search in.
    /// @param id The address of the account.
    /// @return The value of the account.
    function getValueOf(Heap storage heap, address id) internal view returns (uint256) {
        uint256 index = heap.indexOf[id];

        if (!_containsAccount(heap, index, heap.accounts.length, id)) return 0;
        else return heap.accounts[index].value;
    }

    /// @notice Returns the address at the head of the `heap`.
    /// @param heap The heap to get the head.
    /// @return The address of the head.
    function getRoot(Heap storage heap) internal view returns (address) {
        if (heap.accounts.length > 0) return heap.accounts[_ROOT].id;
        else return address(0);
    }

    /// @notice Returns the address of the parent node of the given address in the `heap`, returns the zero address if it's the root or if the address is not in the heap.
    /// @param heap The heap in which to search for the parent.
    /// @param id The address to get the parent.
    /// @return The address of the parent.
    function getParent(Heap storage heap, address id) internal view returns (address) {
        uint256 index = heap.indexOf[id];

        unchecked {
            if (index == 0) return address(0);
            else return heap.accounts[(index - 1) >> 1].id;
        }
    }

    /// @notice Returns the address of the left child of the given address, returns the zero address if it's not in the heap or if it has no left child.
    /// @param heap The heap in which to search for the left child.
    /// @param id The address to get the left child.
    /// @return The address of the left child.
    function getLeftChild(Heap storage heap, address id) internal view returns (address) {
        uint256 index = heap.indexOf[id];
        uint256 accountsLength = heap.accounts.length;

        if (!_containsAccount(heap, index, accountsLength, id)) {
            return address(0);
        } else if ((index = (index << 1) + 1) >= accountsLength) {
            return address(0);
        } else {
            return heap.accounts[index].id;
        }
    }

    /// @notice Returns the address of the right child of the given address, returns the zero address if it's not in the heap or if it has no right child.
    /// @param heap The heap in which to search for the right child.
    /// @param id The address to get the right child.
    /// @return The address of the right child.
    function getRightChild(Heap storage heap, address id) internal view returns (address) {
        uint256 index = heap.indexOf[id];
        uint256 accountsLength = heap.accounts.length;

        if (!_containsAccount(heap, index, accountsLength, id)) {
            return address(0);
        } else if ((index = (index << 1) + 2) >= accountsLength) {
            return address(0);
        } else {
            return heap.accounts[index].id;
        }
    }

    /// @notice Inserts an account in the `heap`.
    /// @param heap The heap to modify.
    /// @param id The address of the account to insert.
    /// @param value The value of the account to insert.
    function insert(Heap storage heap, address id, uint256 value) internal {
        if (id == address(0)) revert AddressIsZero();

        uint256 accountsLength = heap.accounts.length;
        if (_containsAccount(heap, heap.indexOf[id], accountsLength, id)) revert AccountAlreadyInserted();

        heap.accounts.push();

        _shiftUp(heap, Account(id, value), accountsLength);
    }

    /// @notice Decreases the amount of an account in the `heap`.
    /// @param heap The heap to modify.
    /// @param id The address of the account to decrease the amount.
    /// @param newValue The new value of the account.
    function decrease(Heap storage heap, address id, uint256 newValue) internal {
        uint256 index = heap.indexOf[id];

        if (!_containsAccount(heap, index, heap.accounts.length, id)) revert AccountDoesNotExist();
        if (newValue >= heap.accounts[index].value) revert WrongValue();

        _shiftDown(heap, heap.accounts.length, Account(id, newValue), index);
    }

    /// @notice Increases the amount of an account in the `heap`.
    /// @dev Only call this function when `id` is in the `heap` with a smaller value than `newValue`.
    /// @param heap The heap to modify.
    /// @param id The address of the account to increase the amount.
    /// @param newValue The new value of the account.
    function increase(Heap storage heap, address id, uint256 newValue) internal {
        uint256 index = heap.indexOf[id];

        if (!_containsAccount(heap, index, heap.accounts.length, id)) revert AccountDoesNotExist();
        if (newValue <= heap.accounts[index].value) revert WrongValue();

        _shiftUp(heap, Account(id, newValue), index);
    }

    /// @notice Removes an account in the `heap`.
    /// @dev Only call when `id` is in the `heap`.
    /// @param heap The heap to modify.
    /// @param id The address of the account to remove.
    function remove(Heap storage heap, address id) internal {
        uint256 index = heap.indexOf[id];
        uint256 accountsLength = heap.accounts.length;

        if (!_containsAccount(heap, index, accountsLength, id)) revert AccountDoesNotExist();

        delete heap.indexOf[id];

        unchecked {
            if (index == --accountsLength) {
                heap.accounts.pop();
            } else {
                Account memory lastAccount = heap.accounts[accountsLength];
                heap.accounts.pop();

                if (heap.accounts[index].value > lastAccount.value) {
                    _shiftDown(heap, accountsLength, lastAccount, index);
                } else {
                    _shiftUp(heap, lastAccount, index);
                }
            }
        }
    }

    /* PRIVATE */

    /// @notice Sets `index` in the `heap` to be `account`.
    /// @dev The heap may lose its invariant about the order of the values stored.
    /// @dev Only call this function with an index within array's bounds.
    /// @param heap The heap to modify.
    /// @param account The account to set the `index` to.
    /// @param index The index of the account in the heap to be set.
    function _setAccount(Heap storage heap, Account memory account, uint256 index) private {
        heap.accounts[index] = account;
        heap.indexOf[account.id] = index;
    }

    /// @notice Moves an account up the heap until its value is smaller than the one of its parent.
    /// @dev This functions restores the invariant about the order of the values stored when the account to move is the only one with value greater than what it should be.
    /// @param heap The heap to modify.
    /// @param accountToShift The account to move.
    /// @param index The index of the account to move.
    function _shiftUp(Heap storage heap, Account memory accountToShift, uint256 index) private {
        uint256 valueToShift = accountToShift.value;
        Account memory parentAccount;
        uint256 parentIndex;

        unchecked {
            // `index` is checked to be greater than 0 before subtracting 1.
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
    /// @param size The size of the heap.
    /// @param accountToShift The account to move.
    /// @param index The index of the account to move.
    function _shiftDown(Heap storage heap, uint256 size, Account memory accountToShift, uint256 index) private {
        uint256 valueToShift = accountToShift.value;
        uint256 childIndex = (index << 1) + 1;
        uint256 rightChildIndex;

        unchecked {
            while (childIndex < size) {
                // At this point, childIndex (resp. childIndex+1) is the index of the left (resp. right) child.
                Account memory childToSwap = heap.accounts[childIndex];

                // Find the child with largest value.
                rightChildIndex = childIndex + 1; // This cannot overflow because childIndex < size.

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
        }

        _setAccount(heap, accountToShift, index);
    }

    /// @notice Checks if an account with the given address `id` exists in the `heap`.
    /// @dev The parameters `index`, `accountsLength`, and `id` must be coherent.
    /// @param heap The heap to search in.
    /// @param index The index to search for the account in.
    /// @param accountsLength The length of the `heap` accounts array.
    /// @param id The address of the account to search for.
    /// @return True if the account exists in the `heap`, false otherwise.
    function _containsAccount(Heap storage heap, uint256 index, uint256 accountsLength, address id)
        private
        view
        returns (bool)
    {
        if (index != 0) {
            return true;
        } else if (accountsLength != 0) {
            return heap.accounts[0].id == id;
        } else {
            return false;
        }
    }
}
