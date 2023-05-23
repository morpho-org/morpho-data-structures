// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import {ThreeHeapOrderingMock} from "./mocks/ThreeHeapOrderingMock.sol";

contract Heap is ThreeHeapOrderingMock, StdUtils {
    address[] internal accountsUsed;
    mapping(address => bool) internal isUsed;

    uint256 public constant MAX_SORTED_USERS = 16;

    /* Functions to fuzz */

    function insertNewUser(address account, uint96 amount) external {
        if (account == address(0) || isUsed[account]) {
            return;
        }
        update(account, 0, bound(amount, 1, type(uint96).max), MAX_SORTED_USERS);
        accountsUsed.push(account);
        isUsed[account] = true;
    }

    function increaseExistingUser(uint256 index, uint96 amount) external {
        if (accountsUsed.length == 0) {
            return;
        }
        index = bound(index, 0, accountsUsed.length - 1);
        address account = accountsUsed[index];
        uint256 accountValue = getValueOf(account);
        if (accountValue >= type(uint96).max) {
            return;
        }
        update(account, accountValue, bound(amount, accountValue + 1, type(uint96).max), MAX_SORTED_USERS);
    }

    function decreaseExistingUser(uint256 index, uint96 amount) external {
        if (accountsUsed.length == 0) {
            return;
        }
        index = bound(index, 0, accountsUsed.length - 1);
        address account = accountsUsed[index];
        uint256 accountValue = getValueOf(account);
        if (accountValue <= 1) {
            return;
        }
        update(account, accountValue, bound(amount, 1, accountValue - 1), MAX_SORTED_USERS);
    }

    function removeExistingUser(uint256 index) external {
        if (accountsUsed.length == 0) return;
        index = bound(index, 0, accountsUsed.length - 1);
        address account = accountsUsed[index];
        update(account, getValueOf(account), 0, MAX_SORTED_USERS);
        isUsed[account] = false;
        accountsUsed[index] = accountsUsed[accountsUsed.length - 1];
        accountsUsed.pop();
    }
}

contract TestThreeHeapOrderingInvariant is Test {
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
    // value[i] >= value[3i + 1] and value[i] >= value[3i + 2] and value[i] >= value[3i + 3]
    function invariantHeap() public {
        uint256 length = heap.length();

        for (uint256 i; i < length; ++i) {
            assertTrue((i * 3 + 1 >= length || i * 3 + 1 >= heap.size() || heap.accountsValue(i) >= heap.accountsValue(i * 3 + 1)));// forgefmt: disable-line
            assertTrue((i * 3 + 2 >= length || i * 3 + 2 >= heap.size() || heap.accountsValue(i) >= heap.accountsValue(i * 3 + 2)));// forgefmt: disable-line
            assertTrue((i * 3 + 3 >= length || i * 3 + 3 >= heap.size() || heap.accountsValue(i) >= heap.accountsValue(i * 3 + 3)));// forgefmt: disable-line
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
    // size <= 3 * MAX_SORTED_USERS
    function invariantSize() public {
        assertTrue(heap.size() <= 3 * heap.MAX_SORTED_USERS());
    }
}
