// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library UnsortedDLL {
    /// STRUCTS ///

    struct Account {
        address prev;
        address next;
    }

    struct List {
        mapping(address => Account) accounts;
    }

    /// ERRORS ///

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// INTERNAL ///

    /// @notice Returns the address at the head or at the tail of the `_list`.
    /// @param _list The list from which to get the first address.
    /// @param _fifo Whether to treat the data-structure as a FIFO (as opposed to a LIFO).
    function getFirst(List storage _list, bool _fifo) internal view returns (address) {
        if (_fifo) return _list.accounts[address(0)].next;
        else return _list.accounts[address(0)].prev;
    }

    /// @notice Returns the following id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @param _fifo Whether to treat the data-structure as a FIFO (as opposed to a LIFO).
    /// @return The address of the following account.
    function getFollowing(
        List storage _list,
        address _id,
        bool _fifo
    ) internal view returns (address) {
        if (_fifo) return _list.accounts[_id].next;
        else return _list.accounts[_id].prev;
    }

    /// @notice Removes an account of the `_list`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    function remove(List storage _list, address _id) internal returns (bool empty) {
        Account memory account = _list.accounts[_id];
        address prev = account.prev;
        address next = account.next;

        empty = (prev == address(0) && next == address(0));

        _list.accounts[account.prev].next = next;
        _list.accounts[account.next].prev = prev;

        delete _list.accounts[_id];
    }

    /// @notice Inserts an account at the tail of the `_list`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    function insert(List storage _list, address _id) internal returns (bool empty) {
        if (_id == address(0)) revert AddressIsZero();

        address tail = _list.accounts[address(0)].prev;
        empty = tail == address(0);

        _list.accounts[address(0)].prev = _id;
        _list.accounts[tail].next = _id;
        _list.accounts[_id].prev = tail;
    }
}
