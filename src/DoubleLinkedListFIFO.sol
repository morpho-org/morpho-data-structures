// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library DoubleLinkedList {
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

    /// @notice Returns the address at the head of the `_list`.
    /// @param _list The list to get the head.
    /// @return The address of the head.
    function getHead(List storage _list) internal view returns (address) {
        return _list.accounts[address(0)].next;
    }

    /// @notice Returns the address at the tail of the `_list`.
    /// @param _list The list to get the tail.
    /// @return The address of the tail.
    function getTail(List storage _list) internal view returns (address) {
        return _list.accounts[address(0)].prev;
    }

    /// @notice Returns the next id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the next account.
    function getNext(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].next;
    }

    /// @notice Returns the previous id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the previous account.
    function getPrev(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].prev;
    }

    /// @notice Removes an account of the `_list`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    function remove(List storage _list, address _id) internal {
        Account memory account = _list.accounts[_id];

        _list.accounts[account.prev].next = account.next;
        _list.accounts[account.next].prev = account.prev;

        delete _list.accounts[_id];
    }

    /// @notice Inserts an account at the tail of the `_list`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    function insert(List storage _list, address _id) internal {
        if (_id == address(0)) revert AddressIsZero();

        address tail = _list.accounts[address(0)].prev;

        _list.accounts[address(0)].prev = _id;
        _list.accounts[tail].next = _id;
        _list.accounts[_id].prev = tail;
    }
}
