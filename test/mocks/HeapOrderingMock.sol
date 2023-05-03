// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {HeapOrdering} from "src/HeapOrdering.sol";
import {IHeapOrderingMock} from "./IHeapOrderingMock.sol";

contract HeapOrderingMock is IHeapOrderingMock {
    using HeapOrdering for HeapOrdering.HeapArray;

    HeapOrdering.HeapArray internal heap;

    function accountsValue(uint256 index) external view returns (uint256) {
        return heap.accounts[index].value;
    }

    function accountsId(uint256 index) external view returns (address) {
        return heap.accounts[index].id;
    }

    function indexOf(address id) external view returns (uint256) {
        return heap.indexOf[id];
    }

    function update(address id, uint256 formerValue, uint256 newValue, uint256 maxSortedUsers) external {
        heap.update(id, formerValue, newValue, maxSortedUsers);
    }

    function length() external view returns (uint256) {
        return heap.length();
    }

    function size() external view returns (uint256) {
        return heap.size;
    }

    function getValueOf(address id) external view returns (uint256) {
        return heap.getValueOf(id);
    }

    function getHead() external view returns (address) {
        return heap.getHead();
    }

    function getTail() external view returns (address) {
        return heap.getTail();
    }

    function getPrev(address id) external view returns (address) {
        return heap.getPrev(id);
    }

    function getNext(address id) external view returns (address) {
        return heap.getNext(id);
    }
}
