// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "@contracts/HeapOrdering.sol";

contract HeapOrderingStorage {
    using HeapOrdering for HeapOrdering.HeapArray;
    uint256 public TESTED_SIZE = 10000;
    uint128 public MAX_SORTED_USERS = 50;
    uint256 public incrementAmount = 5;

    HeapOrdering.HeapArray internal heap;

    function setUp() public {
        for (uint256 i = 0; i < TESTED_SIZE; i++) {
            address id = address(uint160(i + 1));
            heap.accounts.push(HeapOrdering.Account(id, TESTED_SIZE - i));
            heap.ranks[id] = heap.accounts.length;
        }
    }

    function update(
        address _id,
        uint256 _formerValue,
        uint256 _newValue,
        uint256 _maxSortedUsers
    ) public {
        HeapOrdering.update(heap, _id, _formerValue, _newValue, _maxSortedUsers);
    }
}

contract TestStressHeapOrdering is DSTest {
    HeapOrderingStorage public hs = new HeapOrderingStorage();
    uint256 public ts;
    uint256 public im;
    uint256 public msu;

    function setUp() public {
        hs.setUp();
        ts = hs.TESTED_SIZE();
        im = hs.incrementAmount();
        msu = hs.MAX_SORTED_USERS();
    }

    function testInsertOneTop() public {
        hs.update(address(this), 0, ts + 1, msu);
    }

    function testInsertOneMiddle() public {
        hs.update(address(this), 0, ts / 2, msu);
    }

    function testInsertOneBottom() public {
        hs.update(address(this), 0, 1, msu);
    }

    function testRemoveOneTop() public {
        hs.update(address(uint160(1)), ts, 0, msu);
    }

    function testRemoveOneMiddle() public {
        uint256 middle = ts / 2;
        hs.update(address(uint160(middle + 1)), ts - middle, 0, msu);
    }

    function testRemoveOneBottom() public {
        uint256 end = ts - 2 * im;
        hs.update(address(uint160(end + 1)), ts - end, 0, msu);
    }

    function testIncreaseOneTop() public {
        hs.update(address(uint160(1)), ts, ts + im, msu);
    }

    function testIncreaseOneMiddle() public {
        uint256 middle = ts / 2;
        hs.update(address(uint160(middle + 1)), ts - middle, ts - middle + im, msu);
    }

    function testIncreaseOneBottom() public {
        uint256 end = ts - 2 * im;
        hs.update(address(uint160(end + 1)), ts - end, ts - end + im, msu);
    }

    function testDecreaseOneTop() public {
        hs.update(address(uint160(1)), ts, 1, msu);
    }

    function testDecreaseOneMiddle() public {
        uint256 middle = ts / 2;
        hs.update(address(uint160(middle + 1)), ts - middle, 1, msu);
    }

    function testDecreaseOneBottom() public {
        uint256 end = ts - 2 * im;
        hs.update(address(uint160(end + 1)), ts - end, ts - end - im, msu);
    }
}
