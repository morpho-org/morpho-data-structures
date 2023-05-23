// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BasicHeap} from "src/Heap.sol";

contract HeapMock {
    using BasicHeap for BasicHeap.Heap;

    /* STORAGE */

    BasicHeap.Heap internal heap;

    /* PUBLIC */

    function insert(address id, uint256 value) public {
        heap.insert(id, value);
    }

    function decrease(address id, uint256 newValue) public {
        heap.decrease(id, newValue);
    }

    function increase(address id, uint256 newValue) public {
        heap.increase(id, newValue);
    }

    function remove(address id) public {
        heap.remove(id);
    }

    function length() public view returns (uint256) {
        return heap.length();
    }

    function containsAccount(address id) public view returns (bool) {
        return heap.containsAccount(id);
    }

    function getValueOf(address id) public view returns (uint256) {
        return heap.getValueOf(id);
    }

    function getRoot() public view returns (address) {
        return heap.getRoot();
    }

    function getParent(address id) public view returns (address) {
        return heap.getParent(id);
    }

    function getLeftChild(address id) public view returns (address) {
        return heap.getLeftChild(id);
    }

    function getRightChild(address id) public view returns (address) {
        return heap.getRightChild(id);
    }
}
