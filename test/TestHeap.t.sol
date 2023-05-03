// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {BasicHeap} from "src/Heap.sol";

contract TestHeap is Test {
    using BasicHeap for BasicHeap.Heap;

    /* STORAGE */

    uint256 public TESTED_SIZE = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    BasicHeap.Heap internal _heap;

    /* PUBLIC */

    function setUp() public {
        accounts = new address[](TESTED_SIZE);
        accounts[0] = address(bytes20(keccak256("TestHeap.accounts")));
        for (uint256 i = 1; i < TESTED_SIZE; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount() public {
        _heap.insert(accounts[0], 1);

        assertEq(_heap.length(), 1);
        assertEq(_heap.getValueOf(accounts[0]), 1);
        assertEq(_heap.getRoot(), accounts[0]);
        assertEq(_heap.getLeftChild(accounts[0]), ADDR_ZERO);
        assertEq(_heap.getRightChild(accounts[0]), ADDR_ZERO);
    }

    function testShouldNotInsertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        _heap.insert(ADDR_ZERO, 10);
    }

    function testShouldNotInsertSeveralTimesTheSameAccount() public {
        _heap.insert(accounts[0], 1);
        vm.expectRevert(abi.encodeWithSignature("AccountAlreadyInserted()"));
        _heap.insert(accounts[0], 2);
    }

    function testShouldNotRemoveAccountThatDoesNotExist() public {
        vm.expectRevert(abi.encodeWithSignature("AccountDoesNotExist()"));
        _heap.remove(accounts[0]);
    }

    function testContainsAccount() public {
        for (uint256 i; i < TESTED_SIZE; ++i) {
            _heap.insert(accounts[i], (i + TESTED_SIZE / 2) % TESTED_SIZE);
            for (uint256 j; j < TESTED_SIZE; ++j) {
                assertEq(_heap.containsAccount(accounts[j]), j <= i);
            }
        }
    }

    function testShouldHaveTheRightOrder() public {
        _heap.insert(accounts[0], 20);
        _heap.insert(accounts[1], 40);
        address root = _heap.getRoot();
        address leftChild = _heap.getLeftChild(root);
        assertEq(root, accounts[1]);
        assertEq(leftChild, accounts[0]);
    }

    function testShouldRemoveOneSingleAccount() public {
        _heap.insert(accounts[0], 1);
        _heap.remove(accounts[0]);

        assertEq(_heap.length(), 0);
        assertEq(_heap.getRoot(), ADDR_ZERO);
        assertEq(_heap.getValueOf(accounts[0]), 0);
        assertEq(_heap.getLeftChild(accounts[0]), ADDR_ZERO);
        assertEq(_heap.getRightChild(accounts[0]), ADDR_ZERO);
    }

    function testShouldInsertTwoAccounts() public {
        _heap.insert(accounts[0], 2);
        _heap.insert(accounts[1], 1);

        address root = _heap.getRoot();
        address leftChild = _heap.getLeftChild(root);
        address rightChild = _heap.getRightChild(root);

        assertEq(_heap.length(), 2);
        assertEq(root, accounts[0]);
        assertEq(leftChild, accounts[1]);
        assertEq(rightChild, ADDR_ZERO);
        assertEq(_heap.getParent(leftChild), root);
        assertEq(_heap.getParent(rightChild), ADDR_ZERO);
        assertEq(_heap.getValueOf(accounts[0]), 2);
        assertEq(_heap.getValueOf(accounts[1]), 1);
    }

    function testShouldInsertThreeAccounts() public {
        _heap.insert(accounts[0], 3);
        _heap.insert(accounts[1], 2);
        _heap.insert(accounts[2], 1);

        address root = _heap.getRoot();
        address leftChild = _heap.getLeftChild(root);
        address rightChild = _heap.getRightChild(root);

        assertEq(_heap.length(), 3);
        assertEq(root, accounts[0]);
        assertEq(leftChild, accounts[1]);
        assertEq(rightChild, accounts[2]);
        assertEq(_heap.getParent(leftChild), root);
        assertEq(_heap.getParent(rightChild), root);
        assertEq(_heap.getValueOf(accounts[0]), 3);
        assertEq(_heap.getValueOf(accounts[1]), 2);
        assertEq(_heap.getValueOf(accounts[2]), 1);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        _heap.insert(accounts[0], 2);
        _heap.insert(accounts[1], 1);
        _heap.remove(accounts[0]);

        address root = _heap.getRoot();

        assertEq(_heap.length(), 1);
        assertEq(root, accounts[1]);
        assertEq(_heap.getValueOf(accounts[0]), 0);
        assertEq(_heap.getValueOf(accounts[1]), 1);
        assertEq(_heap.getParent(root), ADDR_ZERO);
        assertEq(_heap.getRightChild(root), ADDR_ZERO);
        assertEq(_heap.getLeftChild(root), ADDR_ZERO);
    }

    function testShouldRemoveBothAccounts() public {
        _heap.insert(accounts[0], 2);
        _heap.insert(accounts[1], 1);
        _heap.remove(accounts[0]);
        _heap.remove(accounts[1]);

        assertEq(_heap.getRoot(), ADDR_ZERO);
        assertEq(_heap.length(), 0);
    }

    function testShouldInsertThreeAccountsAndRemoveThem() public {
        _heap.insert(accounts[0], 3);
        _heap.insert(accounts[1], 2);
        _heap.insert(accounts[2], 1);

        address root = _heap.getRoot();

        assertEq(_heap.length(), 3);
        assertEq(root, accounts[0]);
        assertEq(_heap.getLeftChild(root), accounts[1]);
        assertEq(_heap.getRightChild(root), accounts[2]);

        // Remove account 0.
        _heap.remove(accounts[0]);

        root = _heap.getRoot();

        assertEq(_heap.length(), 2);
        assertEq(root, accounts[1]);
        assertEq(_heap.getLeftChild(root), accounts[2]);
        assertEq(_heap.getRightChild(root), ADDR_ZERO);

        // Remove account 1.
        _heap.remove(accounts[1]);

        root = _heap.getRoot();

        assertEq(_heap.length(), 1);
        assertEq(root, accounts[2]);
        assertEq(_heap.getLeftChild(root), ADDR_ZERO);
        assertEq(_heap.getRightChild(root), ADDR_ZERO);

        // Remove account 2.
        _heap.remove(accounts[2]);

        assertEq(_heap.length(), 0);
        assertEq(_heap.getRoot(), ADDR_ZERO);
    }

    function testShouldInsertAccountsAllSorted() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            _heap.insert(accounts[i], TESTED_SIZE - i);
        }

        assertEq(_heap.getRoot(), accounts[0]);

        for (uint256 i = 0; i < accounts.length; i++) {
            assertEq(_heap.accounts[i].id, accounts[i]);
        }
    }

    function testShouldRemoveAllSortedAccount() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            _heap.insert(accounts[i], TESTED_SIZE - i);
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            _heap.remove(accounts[i]);
        }

        assertEq(_heap.length(), 0);
        assertEq(_heap.getRoot(), ADDR_ZERO);
    }

    function testShouldInsertAccountSortedAtTheBeginning() public {
        uint256 value = 50;

        // Add first 10 accounts with decreasing value.
        for (uint256 i = 0; i < 10; i++) {
            _heap.insert(accounts[i], value - i);
        }

        // Add last 10 accounts at the same value.
        for (uint256 i = TESTED_SIZE - 10; i < TESTED_SIZE; i++) {
            _heap.insert(accounts[i], 10);
        }

        assertEq(_heap.getRoot(), accounts[0], "root not expected");

        for (uint256 i = 0; i < 10; i++) {
            assertEq(_heap.accounts[i].id, accounts[i], "order not expected, 1");
        }

        for (uint256 i = 0; i < 10; i++) {
            assertEq(_heap.accounts[10 + i].id, accounts[TESTED_SIZE - 10 + i], "order not expected, 2");
        }
    }

    function testDecreaseOrder1() public {
        _heap.insert(accounts[0], 4);
        _heap.insert(accounts[1], 3);
        _heap.insert(accounts[2], 2);
        _heap.decrease(accounts[0], 1);

        assertEq(_heap.accounts[0].value, 3);
        assertEq(_heap.accounts[1].value, 1);
        assertEq(_heap.accounts[2].value, 2);
    }

    function testDecreaseOrder2() public {
        _heap.insert(accounts[0], 4);
        _heap.insert(accounts[1], 2);
        _heap.insert(accounts[2], 3);
        _heap.decrease(accounts[0], 1);

        assertEq(_heap.accounts[0].value, 3);
        assertEq(_heap.accounts[1].value, 2);
        assertEq(_heap.accounts[2].value, 1);
    }

    function testIncreaseOrder() public {
        _heap.insert(accounts[0], 4);
        _heap.insert(accounts[1], 3);
        _heap.insert(accounts[2], 2);
        _heap.increase(accounts[2], 5);

        assertEq(_heap.accounts[0].value, 5);
        assertEq(_heap.accounts[1].value, 3);
        assertEq(_heap.accounts[2].value, 4);
    }

    function testRemoveShiftDown() public {
        _heap.insert(accounts[0], 10);
        _heap.insert(accounts[1], 9);
        _heap.insert(accounts[2], 3);
        _heap.insert(accounts[3], 8);
        _heap.insert(accounts[4], 7);
        _heap.insert(accounts[5], 2);
        _heap.insert(accounts[6], 1);

        assertEq(_heap.accounts[0].value, 10);
        assertEq(_heap.accounts[1].value, 9);
        assertEq(_heap.accounts[2].value, 3);
        assertEq(_heap.accounts[3].value, 8);
        assertEq(_heap.accounts[4].value, 7);
        assertEq(_heap.accounts[5].value, 2);
        assertEq(_heap.accounts[6].value, 1);

        _heap.remove(accounts[1]);

        assertEq(_heap.accounts[0].value, 10);
        assertEq(_heap.accounts[1].value, 8);
        assertEq(_heap.accounts[2].value, 3);
        assertEq(_heap.accounts[3].value, 1);
        assertEq(_heap.accounts[4].value, 7);
        assertEq(_heap.accounts[5].value, 2);
    }

    function testRemoveShiftUp() public {
        _heap.insert(accounts[0], 10);
        _heap.insert(accounts[1], 3);
        _heap.insert(accounts[2], 9);
        _heap.insert(accounts[3], 2);
        _heap.insert(accounts[4], 1);
        _heap.insert(accounts[5], 8);
        _heap.insert(accounts[6], 7);

        assertEq(_heap.accounts[0].value, 10);
        assertEq(_heap.accounts[1].value, 3);
        assertEq(_heap.accounts[2].value, 9);
        assertEq(_heap.accounts[3].value, 2);
        assertEq(_heap.accounts[4].value, 1);
        assertEq(_heap.accounts[5].value, 8);
        assertEq(_heap.accounts[6].value, 7);

        _heap.remove(accounts[4]);

        assertEq(_heap.accounts[0].value, 10);
        assertEq(_heap.accounts[1].value, 7);
        assertEq(_heap.accounts[2].value, 9);
        assertEq(_heap.accounts[3].value, 2);
        assertEq(_heap.accounts[4].value, 3);
        assertEq(_heap.accounts[5].value, 8);
    }
}
