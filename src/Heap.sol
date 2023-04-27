// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library BasicHeap {
    struct Account {
        address id; // The address of the account.
        uint256 value; // The value of the account.
    }

    struct Heap {
        Account[] accounts; // All the accounts.
        mapping(address => uint256) indexOf; // A mapping from an address to an index in accounts. From index i, the parent index is (i-1)/2, the left child index is 2*i+1 and the right child index is 2*i+2.
    }

    /// CONSTANTS ///

    uint256 private constant ROOT = 0;

    /// ERRORS ///

    /// @notice Thrown when trying to modify an account with a wrong value.
    error WrongValue();

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// @notice Thrown when the account is already inserted in the heap.
    error AccountAlreadyInserted();

    /// @notice Thrown when the account to modify does not exist.
    error AccountDoesNotExist();

    /// INTERNAL ///

    /// @notice Inserts an account in the `_heap`.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to insert.
    /// @param _value The value of the account to insert.
    function insert(Heap storage _heap, address _id, uint256 _value) internal {
        if (_id == address(0)) revert AddressIsZero();

        uint256 accountsLength = _heap.accounts.length;
        if (containsAccount(_heap, _heap.indexOf[_id], accountsLength, _id)) revert AccountAlreadyInserted();

        _heap.accounts.push();

        shiftUp(_heap, Account(_id, _value), accountsLength);
    }

    /// @notice Decreases the amount of an account in the `_heap`.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to decrease the amount.
    /// @param _newValue The new value of the account.
    function decrease(Heap storage _heap, address _id, uint256 _newValue) internal {
        uint256 index = _heap.indexOf[_id];

        if ((!containsAccount(_heap, index, _heap.accounts.length, _id))) revert AccountDoesNotExist();
        if (_newValue >= _heap.accounts[index].value) revert WrongValue();

        shiftDown(_heap, _heap.accounts.length, Account(_id, _newValue), index);
    }

    /// @notice Increases the amount of an account in the `_heap`.
    /// @dev Only call this function when `_id` is in the `_heap` with a smaller value than `_newValue`.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to increase the amount.
    /// @param _newValue The new value of the account.
    function increase(Heap storage _heap, address _id, uint256 _newValue) internal {
        uint256 index = _heap.indexOf[_id];

        if ((!containsAccount(_heap, index, _heap.accounts.length, _id))) revert AccountDoesNotExist();
        if (_newValue <= _heap.accounts[index].value) revert WrongValue();

        shiftUp(_heap, Account(_id, _newValue), index);
    }

    /// @notice Removes an account in the `_heap`.
    /// @dev Only call when `_id` is in the `_heap`.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to remove.
    function remove(Heap storage _heap, address _id) internal {
        uint256 index = _heap.indexOf[_id];
        uint256 accountsLength = _heap.accounts.length;

        if ((!containsAccount(_heap, index, accountsLength, _id))) revert AccountDoesNotExist();

        delete _heap.indexOf[_id];

        unchecked {
            if (index == --accountsLength) {
                _heap.accounts.pop();
            } else {
                Account memory lastAccount = _heap.accounts[accountsLength];
                _heap.accounts.pop();

                if (_heap.accounts[index].value > lastAccount.value) {
                    shiftDown(_heap, accountsLength, lastAccount, index);
                } else {
                    shiftUp(_heap, lastAccount, index);
                }
            }
        }
    }

    /// PRIVATE ///

    /// @notice Sets `_index` in the `_heap` to be `_account`.
    /// @dev The heap may lose its invariant about the order of the values stored.
    /// @dev Only call this function with an index within array's bounds.
    /// @param _heap The heap to modify.
    /// @param _account The account to set the `_index` to.
    /// @param _index The index of the account in the heap to be set.
    function setAccount(Heap storage _heap, Account memory _account, uint256 _index) private {
        _heap.accounts[_index] = _account;
        _heap.indexOf[_account.id] = _index;
    }

    /// @notice Moves an account up the heap until its value is smaller than the one of its parent.
    /// @dev This functions restores the invariant about the order of the values stored when the account to move is the only one with value greater than what it should be.
    /// @param _heap The heap to modify.
    /// @param _accountToShift The account to move.
    /// @param _index The index of the account to move.
    function shiftUp(Heap storage _heap, Account memory _accountToShift, uint256 _index) private {
        uint256 valueToShift = _accountToShift.value;
        Account memory parentAccount;
        uint256 parentIndex;

        unchecked {
            // `_index` is checked to be greater than 0 before subtracting 1.
            while (
                _index > ROOT && valueToShift > (parentAccount = _heap.accounts[parentIndex = (_index - 1) >> 1]).value
            ) {
                setAccount(_heap, parentAccount, _index);
                _index = parentIndex;
            }
        }

        setAccount(_heap, _accountToShift, _index);
    }

    /// @notice Moves an account down the heap until its value is greater than the ones of its children.
    /// @dev This functions restores the invariant about the order of the values stored when the account to move is the only one with value smaller than what it should be.
    /// @param _heap The heap to modify.
    /// @param _size The size of the heap.
    /// @param _accountToShift The account to move.
    /// @param _index The index of the account to move.
    function shiftDown(Heap storage _heap, uint256 _size, Account memory _accountToShift, uint256 _index) private {
        uint256 valueToShift = _accountToShift.value;
        uint256 childIndex = (_index << 1) + 1;
        uint256 rightChildIndex;
        // At this point, childIndex (resp. childIndex+1) is the index of the left (resp. right) child.

        while (childIndex < _size) {
            Account memory childToSwap = _heap.accounts[childIndex];

            // Find the child with largest value.
            unchecked {
                rightChildIndex = childIndex + 1; // This cannot overflow because childIndex < size.
            }

            if (rightChildIndex < _size) {
                Account memory rightChild = _heap.accounts[rightChildIndex];
                if (rightChild.value > childToSwap.value) {
                    childToSwap = rightChild;
                    childIndex = rightChildIndex;
                }
            }

            if (childToSwap.value > valueToShift) {
                setAccount(_heap, childToSwap, _index);
                _index = childIndex;
                childIndex = (childIndex << 1) + 1;
            } else {
                break;
            }
        }

        setAccount(_heap, _accountToShift, _index);
    }

    /// @notice Checks if an account with the given address `_id` exists in the `_heap`.
    /// @dev The parameters `_index`, `_accountsLength`, and `_id` must be coherent.
    /// @param _heap The heap to search in.
    /// @param _index The index to search for the account in.
    /// @param _accountsLength The length of the `_heap` accounts array.
    /// @param _id The address of the account to search for.
    /// @return True if the account exists in the `_heap`, false otherwise.
    function containsAccount(Heap storage _heap, uint256 _index, uint256 _accountsLength, address _id)
        private
        view
        returns (bool)
    {
        if (_index != 0) {
            return true;
        } else if (_accountsLength != 0) {
            return _heap.accounts[0].id == _id;
        } else {
            return false;
        }
    }

    /// VIEW ///

    /// @notice Returns the number of users in the `_heap`.
    /// @param _heap The heap parameter.
    /// @return The length of the heap.
    function getSize(Heap storage _heap) internal view returns (uint256) {
        return _heap.accounts.length;
    }

    /// @notice Checks if the account with the given address `_id` exists in the `_heap`.
    /// @param _heap The heap to search in.
    /// @param _id The address of the account to search for.
    /// @return True if the account exists in the heap, false otherwise.
    function containsAccount(Heap storage _heap, address _id) internal view returns (bool) {
        return containsAccount(_heap, _heap.indexOf[_id], _heap.accounts.length, _id);
    }

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _heap The heap to search in.
    /// @param _id The address of the account.
    /// @return The value of the account.
    function getValueOf(Heap storage _heap, address _id) internal view returns (uint256) {
        uint256 index;

        if (!containsAccount(_heap, index = _heap.indexOf[_id], _heap.accounts.length, _id)) return 0;
        else return _heap.accounts[index].value;
    }

    /// @notice Returns the address at the head of the `_heap`.
    /// @param _heap The heap to get the head.
    /// @return The address of the head.
    function getRoot(Heap storage _heap) internal view returns (address) {
        if (_heap.accounts.length > 0) return _heap.accounts[ROOT].id;
        else return address(0);
    }

    /// @notice Returns the address of the parent node of the given address in the `_heap`, returns the zero address if it's the root or if the address is not in the heap.
    /// @param _heap The heap in which to search for the parent.
    /// @param _id The address to get the parent.
    /// @return The address of the parent.
    function getParent(Heap storage _heap, address _id) internal view returns (address) {
        uint256 index = _heap.indexOf[_id];

        unchecked {
            if (index == 0) return address(0);
            else return _heap.accounts[(index - 1) >> 1].id;
        }
    }

    /// @notice Returns the address of the left child of the given address, returns the zero address if it's not in the heap or if it has no left child.
    /// @param _heap The heap in which to search for the left child.
    /// @param _id The address to get the left child.
    /// @return The address of the left child.
    function getLeftChild(Heap storage _heap, address _id) internal view returns (address) {
        uint256 index = _heap.indexOf[_id];
        uint256 accountsLength = _heap.accounts.length;

        if (!containsAccount(_heap, index, accountsLength, _id)) {
            return address(0);
        } else if ((index = (index << 1) + 1) >= accountsLength) {
            return address(0);
        } else {
            return _heap.accounts[index].id;
        }
    }

    /// @notice Returns the address of the right child of the given address, returns the zero address if it's not in the heap or if it has no right child.
    /// @param _heap The heap in which to search for the right child.
    /// @param _id The address to get the right child.
    /// @return The address of the right child.
    function getRightChild(Heap storage _heap, address _id) internal view returns (address) {
        uint256 index = _heap.indexOf[_id];
        uint256 accountsLength = _heap.accounts.length;

        if (!containsAccount(_heap, index, accountsLength, _id)) {
            return address(0);
        } else if ((index = (index << 1) + 2) >= accountsLength) {
            return address(0);
        } else {
            return _heap.accounts[index].id;
        }
    }
}
