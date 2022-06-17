// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

library BasicHeap {
    struct Account {
        address id; // The address of the account.
        uint256 value; // The value of the account.
    }

    struct Heap {
        Account[] accounts; // All the accounts.
        mapping(address => uint256) ranks; // A mapping from an address to a rank in accounts. Beware: ranks are shifted by one compared to indexes, so the first rank is 1 and not 0.
    }

    /// ERRORS ///

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// INTERNAL ///

    /// @notice Updates an account in the `_heap`.
    /// @dev Only call with `_id` is in the `_heap` with value `_formerValue` or when `_id` is not in the `_heap` with `_formerValue` equal to 0.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to update.
    /// @param _formerValue The former value of the account to update.
    /// @param _newValue The new value of the account to update.
    function update(
        Heap storage _heap,
        address _id,
        uint256 _formerValue,
        uint256 _newValue
    ) internal {
        if (_formerValue != _newValue) {
            if (_newValue == 0) remove(_heap, _id);
            else if (_formerValue == 0) insert(_heap, _id, _newValue);
            else if (_formerValue < _newValue) increase(_heap, _id, _newValue);
            else decrease(_heap, _id, _newValue);
        }
    }

    /// PRIVATE ///

    /// @notice Returns the account of rank `_rank`.
    /// @dev The first rank is 1 and the last one is the size of the heap.
    /// @dev Only call this function with positive numbers.
    /// @param _heap The heap to search in.
    /// @param _rank The rank of the account.
    /// @return The account of rank `_rank`.
    function getAccount(Heap storage _heap, uint256 _rank) private view returns (Account storage) {
        return _heap.accounts[_rank - 1];
    }

    /// @notice Sets `_index` in the `_heap` to be `_account`.
    /// @dev The heap may lose its invariant about the order of the values stored.
    /// @dev Only call this function with a rank within array's bounds.
    /// @param _heap The heap to modify.
    /// @param _rank The rank of the account in the heap to be set.
    /// @param _account The account to set the `_rank` to.
    function setAccount(
        Heap storage _heap,
        uint256 _rank,
        Account memory _account
    ) private {
        _heap.accounts[_rank - 1] = _account;
        _heap.ranks[_account.id] = _rank;
    }

    /// @notice Sets the value at `_rank` in the `_heap` to be `_newValue`.
    /// @dev The heap may lose its invariant about the order of the values stored.
    /// @dev Only call this function with a rank within array's bounds.
    /// @param _heap The heap to modify.
    /// @param _rank The rank of the account in the heap to be set.
    /// @param _newValue The new value to set the `_rank` to.
    function setAccountValue(
        Heap storage _heap,
        uint256 _rank,
        uint256 _newValue
    ) private {
        _heap.accounts[_rank - 1].value = _newValue;
    }

    /// @notice Swaps two accounts in the `_heap`.
    /// @dev The heap may lose its invariant about the order of the values stored.
    /// @dev Only call this function with ranks within array's bounds.
    /// @param _heap The heap to modify.
    /// @param _rank1 The rank of the first account in the heap.
    /// @param _rank2 The rank of the second account in the heap.
    function swap(
        Heap storage _heap,
        uint256 _rank1,
        uint256 _rank2
    ) private {
        Account memory accountOldRank1 = getAccount(_heap, _rank1);
        Account memory accountOldRank2 = getAccount(_heap, _rank2);
        setAccount(_heap, _rank1, accountOldRank2);
        setAccount(_heap, _rank2, accountOldRank1);
    }

    /// @notice Moves an account up the heap until its value is smaller than the one of its parent.
    /// @dev This functions restores the invariant about the order of the values stored when the account at `_rank` is the only one with value greater than what it should be.
    /// @param _heap The heap to modify.
    /// @param _rank The index of the account to move.
    function shiftUp(Heap storage _heap, uint256 _rank) private {
        Account memory initialAccount = getAccount(_heap, _rank);
        uint256 initialValue = initialAccount.value;
        while (_rank > 1 && initialValue > getAccount(_heap, _rank / 2).value) {
            setAccount(_heap, _rank, getAccount(_heap, _rank / 2));
            _rank /= 2;
        }
        setAccount(_heap, _rank, initialAccount);
    }

    /// @notice Moves an account down the heap until its value is greater than the ones of its children.
    /// @dev This functions restores the invariant about the order of the values stored when the account at `_rank` is the only one with value smaller than what it should be.
    /// @param _heap The heap to modify.
    /// @param _rank The index of the account to move.
    function shiftDown(Heap storage _heap, uint256 _rank) private {
        uint256 size = getSize(_heap);
        Account memory initialAccount = getAccount(_heap, _rank);
        uint256 initialValue = initialAccount.value;
        Account memory childAccount;
        uint256 childRank = _rank * 2;
        // At this point, childRank (resp. childRank+1) is the rank of the left (resp. right) child.

        while (childRank <= size) {
            // Compute the rank of the child with largest value.
            if (
                childRank < size &&
                getAccount(_heap, childRank + 1).value > getAccount(_heap, childRank).value
            ) childRank++;

            childAccount = getAccount(_heap, childRank);

            if (childAccount.value > initialValue) {
                setAccount(_heap, _rank, childAccount);
                _rank = childRank;
                childRank *= 2;
            } else break;
        }
        setAccount(_heap, _rank, initialAccount);
    }

    /// @notice Inserts an account in the `_heap`.
    /// @dev Only call this function when `_id` is not in the `_heap`.
    /// @dev Reverts with AddressIsZero if `_value` is 0.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to insert.
    /// @param _value The value of the account to insert.
    function insert(
        Heap storage _heap,
        address _id,
        uint256 _value
    ) private {
        // _heap cannot contain the 0 address
        if (_id == address(0)) revert AddressIsZero();

        // Put the account at the end of the heap.
        _heap.accounts.push(Account(_id, _value));
        uint256 size = getSize(_heap);
        _heap.ranks[_id] = size;

        // Restore the invariant.
        shiftUp(_heap, size);
    }

    /// @notice Decreases the amount of an account in the `_heap`.
    /// @dev Only call this function when `_id` is in the `_heap` with a value greater than `_newValue`.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to decrease the amount.
    /// @param _newValue The new value of the account.
    function decrease(
        Heap storage _heap,
        address _id,
        uint256 _newValue
    ) private {
        uint256 rank = _heap.ranks[_id];
        setAccountValue(_heap, rank, _newValue);
        shiftDown(_heap, rank);
    }

    /// @notice Increases the amount of an account in the `_heap`.
    /// @dev Only call this function when `_id` is in the `_heap` with a smaller value than `_newValue`.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to increase the amount.
    /// @param _newValue The new value of the account.
    function increase(
        Heap storage _heap,
        address _id,
        uint256 _newValue
    ) private {
        uint256 rank = _heap.ranks[_id];
        setAccountValue(_heap, rank, _newValue);
        shiftUp(_heap, rank);
    }

    /// @notice Removes an account in the `_heap`.
    /// @dev Only call when `_id` is in the `_heap`.
    /// @param _heap The heap to modify.
    /// @param _id The address of the account to remove.
    function remove(Heap storage _heap, address _id) private {
        uint256 rank = _heap.ranks[_id];
        uint256 removedValue = getAccount(_heap, rank).value;
        uint256 size = getSize(_heap);

        if (rank == size) {
            _heap.accounts.pop();
            delete _heap.ranks[_id];
        } else {
            swap(_heap, rank, size);
            _heap.accounts.pop();
            delete _heap.ranks[_id];
            if (getAccount(_heap, rank).value > removedValue) shiftUp(_heap, rank);
            else shiftDown(_heap, rank);
        }
    }

    /// VIEW ///

    /// @notice Returns the size of the `_heap`.
    /// @param _heap The heap parameter.
    /// @return The size of the heap.
    function getSize(Heap storage _heap) internal view returns (uint256) {
        return _heap.accounts.length;
    }

    /// @notice Returns the value of the account linked to `_id`.
    /// @param _heap The heap to search in.
    /// @param _id The address of the account.
    /// @return The value of the account.
    function getValueOf(Heap storage _heap, address _id) internal view returns (uint256) {
        uint256 rank = _heap.ranks[_id];
        if (rank == 0) return 0;
        else return getAccount(_heap, rank).value;
    }

    /// @notice Returns the address at the head of the `_heap`.
    /// @param _heap The heap to get the head.
    /// @return The address of the head.
    function getHead(Heap storage _heap) internal view returns (address) {
        if (getSize(_heap) > 0) return getAccount(_heap, 1).id;
        else return address(0);
    }

    /// @notice Returns the address at the tail of the `_heap`.
    /// @param _heap The heap to get the tail.
    /// @return The address of the tail.
    function getTail(Heap storage _heap) internal view returns (address) {
        uint256 size = getSize(_heap);
        if (size > 0) return getAccount(_heap, size).id;
        else return address(0);
    }

    /// @notice Returns the previous address from the current `_id`.
    /// @param _heap The heap to search in.
    /// @param _id The address of the account.
    /// @return The address of the previous account.
    function getPrev(Heap storage _heap, address _id) internal view returns (address) {
        uint256 rank = _heap.ranks[_id];
        if (rank > 1) return getAccount(_heap, rank - 1).id;
        else return address(0);
    }

    /// @notice Returns the next address from the current `_id`.
    /// @param _heap The heap to search in.
    /// @param _id The address of the account.
    /// @return The address of the next account.
    function getNext(Heap storage _heap, address _id) internal view returns (address) {
        uint256 rank = _heap.ranks[_id];
        if (rank < getSize(_heap)) return getAccount(_heap, rank + 1).id;
        else return address(0);
    }
}
