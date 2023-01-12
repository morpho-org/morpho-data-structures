// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library BucketDLL {
    /// STRUCTS ///

    struct Account {
        address prev;
        address next;
    }

    struct List {
        mapping(address => Account) accounts;
    }

    /// INTERNAL ///

    /// @notice Returns the address at the head of the `_list`.
    /// @param _list The list from which to get the head.
    /// @return The address of the head.
    function getHead(List storage _list) internal view returns (address) {
        return _list.accounts[address(0)].next;
    }

    /// @notice Returns the address at the tail of the `_list`.
    /// @param _list The list from which to get the tail.
    /// @return The address of the tail.
    function getTail(List storage _list) internal view returns (address) {
        return _list.accounts[address(0)].prev;
    }

    /// @notice Returns the next id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the current account.
    /// @return The address of the next account.
    function getNext(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].next;
    }

    /// @notice Returns the previous id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the current account.
    /// @return The address of the previous account.
    function getPrev(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].prev;
    }

    /// @notice Removes an account of the `_list`.
    /// @dev This function should not be called with `_id` equal to address 0.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return empty Whether the bucket is empty after removal.
    function remove(List storage _list, address _id) internal returns (bool empty) {
        Account memory account = _list.accounts[_id];
        address prev = account.prev;
        address next = account.next;

        empty = (prev == address(0) && next == address(0));

        _list.accounts[prev].next = next;
        _list.accounts[next].prev = prev;

        delete _list.accounts[_id];
    }

    /// @notice Inserts an account at the tail of the `_list`.
    /// @dev This function should not be called with `_id` equal to address 0.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @param _head Tells whether to insert at the head or at the tail of the stack.
    /// @return empty Whether the bucket was empty before insertion.
    function insert(
        List storage _list,
        address _id,
        bool _head
    ) internal returns (bool empty) {
        if (_head) {
            address head = _list.accounts[address(0)].next;
            _list.accounts[address(0)].next = _id;
            _list.accounts[head].prev = _id;
            _list.accounts[_id].next = head;
            return head == address(0);
        } else {
            address tail = _list.accounts[address(0)].prev;
            _list.accounts[address(0)].prev = _id;
            _list.accounts[tail].next = _id;
            _list.accounts[_id].prev = tail;
            return tail == address(0);
        }
    }
}
