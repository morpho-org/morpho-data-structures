// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test} from "forge-std/Test.sol";

import {HeapMock} from "../mocks/HeapMock.sol";

contract Heap is HeapMock, StdUtils {
    address[] internal accountsUsed;
    mapping(address => bool) internal isUsed;

    function accountsValue(uint256 index) external view returns (uint256) {
        return heap.accounts[index].value;
    }

    function accountsId(uint256 index) external view returns (address) {
        return heap.accounts[index].id;
    }

    function indexOf(address id) external view returns (uint256) {
        return heap.indexOf[id];
    }

    /// Functions to fuzz ///

    function insertNewUser(address account, uint256 amount) external {
        if (account == address(0) || isUsed[account]) {
            return;
        }
        insert(account, amount);
        accountsUsed.push(account);
        isUsed[account] = true;
    }

    function increaseExistingUser(uint256 index, uint256 amount) external {
        if (accountsUsed.length == 0) {
            return;
        }
        index = bound(index, 0, accountsUsed.length - 1);
        address account = accountsUsed[index];
        uint256 accountValue = getValueOf(account);
        if (accountValue == type(uint256).max) {
            return;
        }
        increase(account, bound(amount, accountValue + 1, type(uint256).max));
    }

    function decreaseExistingUser(uint256 index, uint256 amount) external {
        if (accountsUsed.length == 0) {
            return;
        }
        index = bound(index, 0, accountsUsed.length - 1);
        address account = accountsUsed[index];
        uint256 accountValue = getValueOf(account);
        if (accountValue == 0) {
            return;
        }
        decrease(account, bound(amount, 0, accountValue - 1));
    }

    function removeExistingUser(uint256 index) external {
        if (accountsUsed.length == 0) {
            return;
        }
        index = bound(index, 0, accountsUsed.length - 1);
        remove(accountsUsed[index]);
        isUsed[accountsUsed[index]] = false;
        accountsUsed[index] = accountsUsed[accountsUsed.length - 1];
        accountsUsed.pop();
    }
}

contract TestHeapInvariant is Test {
    /* STRUCTS */

    struct FuzzSelector {
        address addr;
        bytes4[] selectors;
    }

    /* STORAGE */

    Heap public heap;

    /* PUBLIC */

    function setUp() public {
        heap = new Heap();
    }

    // Target specific selectors for invariant testing
    function targetSelectors() public view returns (FuzzSelector[] memory) {
        FuzzSelector[] memory targets = new FuzzSelector[](1);
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = Heap.insertNewUser.selector;
        selectors[1] = Heap.insertNewUser.selector; // more insertions that removals
        selectors[2] = Heap.increaseExistingUser.selector;
        selectors[3] = Heap.decreaseExistingUser.selector;
        selectors[4] = Heap.removeExistingUser.selector;
        targets[0] = FuzzSelector(address(heap), selectors);
        return targets;
    }

    // Rule:
    // For all i in [[0, size]],
    // value[i] >= value[2i + 1] and value[i] >= value[2i + 2]
    function invariantHeap() public {
        uint256 size = heap.length();

        for (uint256 i; i < size; ++i) {
            address account = heap.accountsId(i);
            assertEq(heap.accountsValue(i), heap.getValueOf(account));
            if (i > 0) {
                uint256 parentIndex = (i - 1) / 2;
                assertTrue(heap.accountsValue(i) <= heap.accountsValue(parentIndex));
                assertEq(heap.getParent(account), heap.accountsId(parentIndex));
            } else {
                assertEq(heap.getParent(account), address(0));
            }

            uint256 leftChildIndex = 2 * i + 1;
            uint256 rightChildIndex = 2 * i + 2;
            if (leftChildIndex < size) {
                assertTrue(heap.accountsValue(i) >= heap.accountsValue(leftChildIndex));
                assertEq(heap.getLeftChild(account), heap.accountsId(leftChildIndex));
            } else {
                assertEq(heap.getLeftChild(account), address(0));
            }

            if (rightChildIndex < size) {
                assertTrue(heap.accountsValue(i) >= heap.accountsValue(rightChildIndex));
                assertEq(heap.getRightChild(account), heap.accountsId(rightChildIndex));
            } else {
                assertEq(heap.getRightChild(account), address(0));
            }
        }
    }

    // Rule:
    // For all i in [[0, length]], indexOf[accounts[i].id] == i
    function invariantIndexOf() public {
        uint256 size = heap.length();

        for (uint256 i; i < size; ++i) {
            assertTrue(heap.indexOf(heap.accountsId(i)) == i);
        }
    }
}
