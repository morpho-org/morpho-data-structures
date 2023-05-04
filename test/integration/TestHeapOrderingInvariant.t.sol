// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {HeapOrderingMock} from "../mocks/HeapOrderingMock.sol";
import {HeapOrdering} from "src/HeapOrdering.sol";

contract Heap is HeapOrderingMock {
    using HeapOrdering for HeapOrdering.HeapArray;

    uint256 public MAX_SORTED_USERS = 16;

    /// @dev Function to fuzz
    function updateCorrect(address id, uint96 newValue) public {
        uint256 oldValue = _heap.getValueOf(id);
        if (oldValue != 0 || newValue != 0) {
            _heap.update(id, _heap.getValueOf(id), newValue, MAX_SORTED_USERS);
        }
    }
}

contract TestHeapOrderingInvariant is Test {
    struct FuzzSelector {
        address addr;
        bytes4[] selectors;
    }

    Heap public heap;

    function setUp() public {
        heap = new Heap();
    }

    // Target specific selectors for invariant testing
    function targetSelectors() public view returns (FuzzSelector[] memory) {
        FuzzSelector[] memory targets = new FuzzSelector[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = Heap.updateCorrect.selector;
        targets[0] = FuzzSelector(address(heap), selectors);
        return targets;
    }

    // Rule:
    // For all i in [[0, size]],
    // value[i] >= value[2i + 1] and value[i] >= value[2i + 2]
    function invariantHeap() public {
        uint256 length = heap.length();

        for (uint256 i; i < length; ++i) {
            assertTrue((i * 2 + 1 >= length || i * 2 + 1 >= heap.size() || heap.accountsValue(i) >= heap.accountsValue(i * 2 + 1)));// forgefmt: disable-line
            assertTrue((i * 2 + 2 >= length || i * 2 + 2 >= heap.size() || heap.accountsValue(i) >= heap.accountsValue(i * 2 + 2)));// forgefmt: disable-line
        }
    }

    // Rule:
    // For all i in [[0, length]], indexOf(account.id[i]) == i
    function invariantIndexOf() public {
        uint256 length = heap.length();

        for (uint256 i; i < length; ++i) {
            assertTrue(heap.indexOf(heap.accountsId(i)) == i);
        }
    }

    // Rule:
    // size <= 2 * MAX_SORTED_USERS
    function invariantSize() public {
        assertTrue(heap.size() <= 2 * heap.MAX_SORTED_USERS());
    }
}
