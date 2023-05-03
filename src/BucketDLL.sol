// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title BucketDLL
/// @author Morpho Labs
/// @custom:contact security@morpho.xyz
/// @notice The doubly linked list used in logarithmic buckets.
library BucketDLL {
    /* STRUCTS */

    struct Account {
        address prev;
        address next;
    }

    struct List {
        mapping(address => Account) accounts;
    }

    /* INTERNAL */

    /// @notice Returns the next id address from the current `id`.
    /// @dev Pass the address 0 to get the head of the list.
    /// @param list The list to search in.
    /// @param id The address of the current account.
    /// @return The address of the next account.
    function getNext(List storage list, address id) internal view returns (address) {
        return list.accounts[id].next;
    }

    /// @notice Removes an account of the `list`.
    /// @dev This function should not be called with `id` equal to address 0.
    /// @dev This function should not be called with an `_id` that is not in the list.
    /// @param list The list to search in.
    /// @param id The address of the account.
    /// @return Whether the bucket is empty after removal.
    function remove(List storage list, address id) internal returns (bool) {
        Account memory account = list.accounts[id];
        address prev = account.prev;
        address next = account.next;

        list.accounts[prev].next = next;
        list.accounts[next].prev = prev;

        delete list.accounts[id];

        return (prev == address(0) && next == address(0));
    }

    /// @notice Inserts an account in the `list`.
    /// @dev This function should not be called with `id` equal to address 0.
    /// @dev This function should not be called with an `id` that is already in the list.
    /// @param list The list to search in.
    /// @param id The address of the account.
    /// @param atHead Tells whether to insert at the head or at the tail of the list.
    /// @return Whether the bucket was empty before insertion.
    function insert(
        List storage list,
        address id,
        bool atHead
    ) internal returns (bool) {
        if (atHead) {
            address head = list.accounts[address(0)].next;
            list.accounts[address(0)].next = id;
            list.accounts[head].prev = id;
            list.accounts[id].next = head;
            return head == address(0);
        } else {
            address tail = list.accounts[address(0)].prev;
            list.accounts[address(0)].prev = id;
            list.accounts[tail].next = id;
            list.accounts[id].prev = tail;
            return tail == address(0);
        }
    }
}
