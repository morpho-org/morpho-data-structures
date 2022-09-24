// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "@contracts/HeapOrdering.sol";

contract Heap {
    using HeapOrdering for HeapOrdering.HeapArray;

    uint256 public MAX_SORTED_USERS = 16;
    HeapOrdering.HeapArray public heap;

    /// Functions to fuzz ///

    function update(address _id, uint96 _newValue) public {
        heap.update(_id, heap.getValueOf(_id), _newValue, MAX_SORTED_USERS);
    }

    /// Helpers ///

    function length() public view returns (uint256) {
        return heap.length();
    }

    function size() public view returns (uint256) {
        return heap.size;
    }

    function accountValue(uint256 i) public view returns (uint256) {
        return heap.accounts[i].value;
    }

    function accountId(uint256 i) public view returns (address) {
        return heap.accounts[i].id;
    }

    function indexOf(address id) public view returns (uint256) {
        return heap.indexOf[id];
    }
}

contract TestHeapInvariant is DSTest {
    Heap public heap;

    function setUp() public {
        heap = new Heap();
    }

    // Rule:
    // For all i in [[0, size]],
    // value[i] >= value[2i + 1] and value[i] >= value[2i + 2]
    function invariantHeap() public {
        uint256 length = heap.length();

        for (uint256 i = 1; i < length; ++i) {
            assertTrue(
                (i * 2 + 1 >= length || i * 2 + 1 >= heap.size() || heap.accountValue(i) >= heap.accountValue(i * 2 + 1))
            ); // prettier-ignore
            assertTrue(
                (i * 2 + 2 >= length || i * 2 + 2 >= heap.size() || heap.accountValue(i) >= heap.accountValue(i * 2 + 2))
            ); // prettier-ignore
        }
    }

    // Rule:
    // For all i in [[0, length]], indexOf(account.id[i]) == i
    function invariantIndexOf() public {
        uint256 length = heap.length();

        for (uint256 i = 1; i < length; ++i) {
            assertTrue(heap.indexOf(heap.accountId(i)) == i);
        }
    }

    // Rule:
    // size <= 2 * MAX_SORTED_USERS
    function invariantSize() public {
        assertTrue(heap.size() <= 2 * heap.MAX_SORTED_USERS());
    }
}
