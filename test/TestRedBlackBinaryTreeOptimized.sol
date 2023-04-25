// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {RedBlackBinaryTreeOptimized} from "src/RedBlackBinaryTreeOptimized.sol";

contract TestRedBlackBinaryTreeOptimized is Test {
    using RedBlackBinaryTreeOptimized for RedBlackBinaryTreeOptimized.Tree;

    uint256 public NDS = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    RedBlackBinaryTreeOptimized.Tree public tree;

    function setUp() public {
        accounts = new address[](NDS);
        accounts[0] = address(this);
        for (uint256 i = 1; i < NDS; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertShouldRevertValueEqual0(address key) public {
        vm.assume(key != ADDR_ZERO);
        vm.expectRevert("RBBT:value-cannot-be-0");
        tree.insert(key, 0);
    }

    function testInsertCannotInsertTwiceAnAccount(address key, uint256 value) public {
        vm.assume(value != 0);
        tree.insert(key, value);
        vm.expectRevert("RBBT:account-already-in");
        tree.insert(key, value);
    }

    function testInsertCorrectValue(address key, uint256 value) public {
        vm.assume(value != 0 && key != ADDR_ZERO);
        tree.insert(key, value);
        assertEq(tree.last(), key, "Incorrect key inserted");
        assertEq(tree.first(), key, "Incorrect key inserted");
        assertEq(tree.keyToValue[key], value, "Incorrect value inserted");
    }

    function FirstReturnAddressZeroIfEmpty() public {
        assertEq(tree.first(), ADDR_ZERO, "Address Not Null");
    }

    function LastReturnAddressZeroIfEmpty() public {
        assertEq(tree.last(), ADDR_ZERO, "Address Not Null");
    }

    function testFirstCorrectValue(uint256[] memory values) public {
        vm.assume(values.length > NDS);
        uint256 minValue = type(uint256).max;
        address minValueKey;
        for (uint256 i = 0; i < NDS; ++i) {
            values[i] = bound(values[i], 1, type(uint256).max);
            tree.insert(accounts[i], values[i]);
            if (values[i] < minValue) {
                minValue = values[i];
                minValueKey = accounts[i];
            }
        }
        assertEq(tree.first(), minValueKey, "Incorrect smallest key");
    }

    function testLastCorrectValue(uint256[] memory values) public {
        vm.assume(values.length > NDS);
        uint256 maxValue;
        address maxValueKey;
        for (uint256 i = 0; i < NDS; ++i) {
            values[i] = bound(values[i], 1, type(uint256).max);
            tree.insert(accounts[i], values[i]);
            if (values[i] >= maxValue) {
                maxValue = values[i];
                maxValueKey = accounts[i];
            }
        }
        assertEq(tree.last(), maxValueKey, "Incorrect smallest key");
    }

    function testRemoveShouldRevertIfAccountDoesNotExist(address key) public {
        vm.assume(key != ADDR_ZERO);
        vm.expectRevert("RBBT:account-not-exist");
        tree.remove(key);
    }

    function testRemoveCannotBeDoneTwice(address key, uint256 value) public {
        vm.assume(value != 0 && key != ADDR_ZERO);
        tree.insert(key, value);
        tree.remove(key);
        vm.expectRevert("RBBT:account-not-exist");
        tree.remove(key);
    }

    function testRemove(address key, uint256 value) public {
        vm.assume(value != 0 && key != ADDR_ZERO);
        tree.insert(key, value);
        tree.remove(key);
        assertEq(tree.last(), ADDR_ZERO, "Tree should be empty");
        assertEq(tree.first(), ADDR_ZERO, "Tree should be empty");
        assertEq(tree.keyToValue[key], 0, "Value Not Removed");
    }

    function testRemoveMultipleAccountsWithRandomPosition(
        uint256[] memory seed,
        uint256[] memory values
    ) public {
        vm.assume(values.length > NDS && seed.length > NDS);

        for (uint256 i = 0; i < NDS; ++i) {
            if (seed[i] % 2 == 0) {
                values[i] = bound(values[i], 1, type(uint256).max);
                tree.insert(accounts[i], values[i]);
            }
        }
        for (uint256 i = 0; i < NDS; ++i) {
            if (seed[i] % 2 == 1) {
                vm.expectRevert("RBBT:account-not-exist");
            }
            tree.remove(accounts[i]);
        }
    }

    function testKeyExistsShouldWorkIfAccountInserted(uint256[] memory values) public {
        vm.assume(values.length > NDS);

        for (uint256 i = 0; i < NDS; ++i) {
            values[i] = bound(values[i], 1, type(uint256).max);
            tree.insert(accounts[i], values[i]);
        }
        for (uint256 i = 0; i < NDS; ++i) {
            assertTrue(tree.keyExists(accounts[i]));
            tree.remove(accounts[i]);
            assertFalse(tree.keyExists(accounts[i]));
        }
    }

    function testNextAndPrevFunctionInTree(uint256[] memory values, uint256 seed) public {
        vm.assume(values.length > NDS);

        for (uint256 i = 0; i < NDS; ++i) {
            values[i] = bound(values[i], 1, type(uint256).max);
            tree.insert(accounts[i], values[i]);
        }

        address account = accounts[seed % accounts.length];
        address newAccount;

        while (account != ADDR_ZERO) {
            newAccount = tree.next(account);
            if (newAccount != ADDR_ZERO) {
                assertTrue(
                    RedBlackBinaryTreeOptimized.compare(
                        tree.keyToValue[newAccount],
                        newAccount,
                        tree.keyToValue[account],
                        account
                    )
                );
            }
            account = newAccount;
        }

        while (account != ADDR_ZERO) {
            newAccount = tree.prev(account);
            if (newAccount != ADDR_ZERO) {
                assertTrue(
                    RedBlackBinaryTreeOptimized.compare(
                        tree.keyToValue[account],
                        account,
                        tree.keyToValue[newAccount],
                        newAccount
                    )
                );
            }
            account = newAccount;
        }
    }

    function testCompareIfValueDifferent(
        uint256 valueA,
        address accountA,
        uint256 valueB,
        address accountB
    ) public {
        vm.assume(valueA != valueB);
        if (valueA > valueB) {
            assertTrue(RedBlackBinaryTreeOptimized.compare(valueA, accountA, valueB, accountB));
        } else {
            assertFalse(RedBlackBinaryTreeOptimized.compare(valueA, accountA, valueB, accountB));
        }
    }

    function testCompareShouldReturnTrueIfValuesEquals(
        uint256 value,
        address accountA,
        address accountB
    ) public {
        if (accountA > accountB) {
            assertTrue(RedBlackBinaryTreeOptimized.compare(value, accountA, value, accountB));
        } else {
            assertFalse(RedBlackBinaryTreeOptimized.compare(value, accountA, value, accountB));
        }
    }
}
