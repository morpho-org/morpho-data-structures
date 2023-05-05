// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {BasicHeap} from "src/Heap.sol";

import {HeapMock} from "../mocks/HeapMock.sol";

contract TestHeap is Test {
    /* STORAGE */

    uint256 public constant TESTED_SIZE = 50;

    HeapMock internal heap;

    function _createAccounts(bytes32 seed, uint256 n) internal pure returns (address[] memory accounts) {
        accounts = new address[](n);
        for (uint256 i; i < n; ++i) {
            seed = keccak256(abi.encode(seed));
            accounts[i] = address(bytes20(seed));
        }
    }

    function _createIncreasingValues(bytes32 seed, uint256 min, uint256 max, uint256 n)
        internal
        view
        returns (uint256[] memory values)
    {
        values = new uint256[](n);
        uint256 minValue = min;
        for (uint256 i; i < n; ++i) {
            seed = keccak256(abi.encode(seed));
            values[i] = bound(uint256(seed), minValue, max - (n - i));
            minValue = values[i] + 1;
        }
    }

    function _compareUnorderedTuples(address addrA, address addrB, address addr0, address addr1)
        internal
        pure
        returns (bool)
    {
        return (addrA == addr0 && addrB == addr1) || (addrA == addr1 && addrB == addr0);
    }

    function _assertNodeCorrect(address id, uint256 expectedValue) internal {
        uint256 value = heap.getValueOf(id);
        assertEq(value, expectedValue);

        address root = heap.getRoot();
        address parent = heap.getParent(id);
        address leftChild = heap.getLeftChild(id);
        address rightChild = heap.getRightChild(id);
        assertGe(heap.getValueOf(root), value);
        assertTrue(heap.containsAccount(id));
        assertTrue(id == root || (heap.containsAccount(parent) && heap.getValueOf(parent) >= value));
        assertTrue(leftChild == address(0) || (heap.containsAccount(leftChild) && heap.getValueOf(leftChild) <= value));
        assertTrue(
            rightChild == address(0) || (heap.containsAccount(rightChild) && heap.getValueOf(rightChild) <= value)
        );
    }

    /* PUBLIC */

    function setUp() public {
        heap = new HeapMock();
    }

    function testEmpty(address id) public {
        assertEq(heap.length(), 0);
        assertEq(heap.getRoot(), address(0));
        assertEq(heap.getParent(id), address(0));
        assertEq(heap.getLeftChild(id), address(0));
        assertEq(heap.getRightChild(id), address(0));
        assertEq(heap.getValueOf(id), 0);
        assertFalse(heap.containsAccount(id));
    }

    function testShouldNotInsertZeroAddress(uint256 value) public {
        vm.expectRevert(BasicHeap.AddressIsZero.selector);
        heap.insert(address(0), value);
    }

    function testShouldNotInsertSeveralTimesTheSameAccount(address id, uint256 value1, uint256 value2) public {
        vm.assume(id != address(0));

        heap.insert(id, value1);
        vm.expectRevert(BasicHeap.AccountAlreadyInserted.selector);
        heap.insert(id, value2);
    }

    function testShouldNotModifyAccountThatDoesNotExist(address id, uint256 value) public {
        vm.assume(id != address(0));

        vm.expectRevert(BasicHeap.AccountDoesNotExist.selector);
        heap.remove(id);
        vm.expectRevert(BasicHeap.AccountDoesNotExist.selector);
        heap.increase(id, value);
        vm.expectRevert(BasicHeap.AccountDoesNotExist.selector);
        heap.decrease(id, value);
    }

    function testInsertOneAccount(address id, uint256 value) public {
        vm.assume(id != address(0));

        heap.insert(id, value);

        assertEq(heap.length(), 1);
        assertTrue(heap.containsAccount(id));
        assertEq(heap.getValueOf(id), value);
        assertEq(heap.getRoot(), id);
        assertEq(heap.getParent(id), address(0));
        assertEq(heap.getLeftChild(id), address(0));
        assertEq(heap.getRightChild(id), address(0));
    }

    function testInsertTwoAccounts(bytes32 accountsSeed, bytes32 valuesSeed) public {
        address[] memory ids = _createAccounts(accountsSeed, 2);
        uint256[] memory values = _createIncreasingValues(valuesSeed, 0, type(uint256).max, 2);

        for (uint256 i; i < 2; ++i) {
            heap.insert(ids[i], values[i]);
        }

        assertEq(heap.length(), 2);
        assertEq(heap.getRoot(), ids[1]);
        assertEq(heap.getParent(ids[0]), ids[1]);
        assertTrue(_compareUnorderedTuples(heap.getLeftChild(ids[1]), heap.getRightChild(ids[1]), ids[0], address(0)));
    }

    function testInsertThreeAccounts(bytes32 accountsSeed, bytes32 valuesSeed) public {
        address[] memory ids = _createAccounts(accountsSeed, 3);
        uint256[] memory values = _createIncreasingValues(valuesSeed, 0, type(uint256).max, 3);

        for (uint256 i; i < 3; ++i) {
            heap.insert(ids[i], values[i]);
        }

        assertEq(heap.length(), 3);
        assertEq(heap.getRoot(), ids[2]);
        assertEq(heap.getParent(ids[0]), ids[2]);
        assertEq(heap.getParent(ids[1]), ids[2]);
        assertTrue(_compareUnorderedTuples(heap.getLeftChild(ids[2]), heap.getRightChild(ids[2]), ids[0], ids[1]));
    }

    function testRemoveFirstAccount(bytes32 accountsSeed, bytes32 valuesSeed) public {
        address[] memory ids = _createAccounts(accountsSeed, 3);
        uint256[] memory values = _createIncreasingValues(valuesSeed, 0, type(uint256).max, 3);

        for (uint256 i; i < 3; ++i) {
            heap.insert(ids[i], values[i]);
        }
        heap.remove(ids[2]);

        assertEq(heap.length(), 2);
        assertEq(heap.getRoot(), ids[1]);
        assertEq(heap.getParent(ids[0]), ids[1]);
        assertTrue(_compareUnorderedTuples(heap.getLeftChild(ids[1]), heap.getRightChild(ids[1]), ids[0], address(0)));
    }

    function testDecreaseFirstAccount(bytes32 accountsSeed, bytes32 valuesSeed) public {
        address[] memory ids = _createAccounts(accountsSeed, 3);
        uint256[] memory values = _createIncreasingValues(valuesSeed, 0, type(uint256).max, 3);

        for (uint256 i; i < 3; ++i) {
            heap.insert(ids[i], values[i]);
        }
        heap.decrease(ids[2], 0);

        assertEq(heap.length(), 3);
        assertEq(heap.getRoot(), ids[1]);
        assertEq(heap.getParent(ids[0]), ids[1]);
        assertEq(heap.getParent(ids[2]), ids[1]);
        assertTrue(_compareUnorderedTuples(heap.getLeftChild(ids[1]), heap.getRightChild(ids[1]), ids[0], ids[2]));
    }

    function testIncreaseLastAccount(bytes32 accountsSeed, bytes32 valuesSeed) public {
        address[] memory ids = _createAccounts(accountsSeed, 3);
        uint256[] memory values = _createIncreasingValues(valuesSeed, 0, type(uint256).max - 1, 3);

        for (uint256 i; i < 3; ++i) {
            heap.insert(ids[i], values[i]);
        }
        heap.increase(ids[0], type(uint256).max);

        assertEq(heap.length(), 3);
        assertEq(heap.getRoot(), ids[0]);
        assertEq(heap.getParent(ids[1]), ids[0]);
        assertEq(heap.getParent(ids[2]), ids[0]);
        assertTrue(_compareUnorderedTuples(heap.getLeftChild(ids[0]), heap.getRightChild(ids[0]), ids[1], ids[2]));
    }

    function testInsertMany(bytes32 seed, uint256[TESTED_SIZE] calldata values) public {
        address[] memory ids = _createAccounts(seed, TESTED_SIZE);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.insert(ids[i], values[i]);
            _assertNodeCorrect(ids[i], values[i]);
        }
    }

    function testRemoveMany(bytes32 seed, uint256[TESTED_SIZE] calldata values) public {
        address[] memory ids = _createAccounts(seed, TESTED_SIZE);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.insert(ids[i], values[i]);
        }

        for (uint256 i; i < TESTED_SIZE; ++i) {
            address id = ids[i];
            heap.remove(id);
            assertFalse(heap.containsAccount(id));
            assertEq(heap.getParent(id), address(0));
            assertEq(heap.getLeftChild(id), address(0));
            assertEq(heap.getRightChild(id), address(0));
        }
    }

    function testIncreaseMany(
        bytes32 seed,
        uint256[TESTED_SIZE] memory initialValues,
        uint256[TESTED_SIZE] memory increasedValues
    ) public {
        address[] memory ids = _createAccounts(seed, TESTED_SIZE);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            initialValues[i] = bound(initialValues[i], 0, type(uint256).max - 1);
            increasedValues[i] = bound(increasedValues[i], initialValues[i] + 1, type(uint256).max);
        }

        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.insert(ids[i], initialValues[i]);
        }

        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.increase(ids[i], increasedValues[i]);
            _assertNodeCorrect(ids[i], increasedValues[i]);
        }
    }

    function testDecreaseMany(
        bytes32 seed,
        uint256[TESTED_SIZE] memory initialValues,
        uint256[TESTED_SIZE] memory decreasedValues
    ) public {
        address[] memory ids = _createAccounts(seed, TESTED_SIZE);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            initialValues[i] = bound(initialValues[i], 1, type(uint256).max);
            decreasedValues[i] = bound(decreasedValues[i], 0, initialValues[i] - 1);
        }

        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.insert(ids[i], initialValues[i]);
        }

        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.decrease(ids[i], decreasedValues[i]);
            _assertNodeCorrect(ids[i], decreasedValues[i]);
        }
    }

    function testShouldRemovalsBeSorted(bytes32 seed, uint256[TESTED_SIZE] calldata values) public {
        address[] memory ids = _createAccounts(seed, TESTED_SIZE);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.insert(ids[i], values[i]);
        }

        uint256 previousRootValue = type(uint256).max;
        while (heap.length() > 0) {
            address root = heap.getRoot();
            uint256 rootValue = heap.getValueOf(root);
            assertLe(rootValue, previousRootValue);
            heap.remove(root);
            previousRootValue = rootValue;
        }
    }

    function testLength(
        bytes32 seed,
        uint256[TESTED_SIZE] memory initialValues,
        uint256[TESTED_SIZE] memory decreasedValues,
        uint256[TESTED_SIZE] memory increasedValues
    ) public {
        address[] memory ids = _createAccounts(seed, TESTED_SIZE);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            initialValues[i] = bound(initialValues[i], 1, type(uint256).max);
            decreasedValues[i] = bound(decreasedValues[i], 0, initialValues[i] - 1);
            increasedValues[i] = bound(increasedValues[i], decreasedValues[i] + 1, type(uint256).max);
        }

        uint256 expectedLength = 0;
        assertEq(heap.length(), expectedLength);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.insert(ids[i], initialValues[i]);
            assertEq(heap.length(), ++expectedLength);
        }
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.decrease(ids[i], decreasedValues[i]);
            assertEq(heap.length(), expectedLength);
        }
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.increase(ids[i], increasedValues[i]);
            assertEq(heap.length(), expectedLength);
        }
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.remove(ids[i]);
            assertEq(heap.length(), --expectedLength);
        }
    }

    function testShouldHalfAccountsHaveTwoChildren(bytes32 seed, uint256[TESTED_SIZE] memory values) public {
        address[] memory ids = _createAccounts(seed, TESTED_SIZE);
        for (uint256 i; i < TESTED_SIZE; ++i) {
            heap.insert(ids[i], values[i]);
        }

        uint256 accountsWhithTwoChildren;
        for (uint256 i; i < TESTED_SIZE; ++i) {
            if (heap.getLeftChild(ids[i]) != address(0) && heap.getRightChild(ids[i]) != address(0)) {
                accountsWhithTwoChildren++;
            }
        }
        assertGe(accountsWhithTwoChildren, (TESTED_SIZE - 1) / 2);
    }
}
