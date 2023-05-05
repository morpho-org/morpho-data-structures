// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {ThreeHeapOrdering} from "src/ThreeHeapOrdering.sol";
import {IHeapOrderingMock} from "./interfaces/IHeapOrderingMock.sol";

contract ThreeHeapOrderingMock is IHeapOrderingMock {
    using ThreeHeapOrdering for ThreeHeapOrdering.HeapArray;

    /* STORAGE */

    ThreeHeapOrdering.HeapArray internal heap;

    /* PUBLIC */

    function accountsValue(uint256 index) public view returns (uint256) {
        return heap.accounts[index].value;
    }

    function accountsId(uint256 index) public view returns (address) {
        return heap.accounts[index].id;
    }

    function indexOf(address id) public view returns (uint256) {
        return heap.indexOf[id];
    }

    function update(address id, uint256 formerValue, uint256 newValue, uint256 maxSortedUsers) public {
        heap.update(id, formerValue, newValue, maxSortedUsers);
    }

    function length() public view returns (uint256) {
        return heap.length();
    }

    function size() public view returns (uint256) {
        return heap.size;
    }

    function getValueOf(address id) public view returns (uint256) {
        return heap.getValueOf(id);
    }

    function getHead() public view returns (address) {
        return heap.getHead();
    }

    function getTail() public view returns (address) {
        return heap.getTail();
    }

    function getPrev(address id) public view returns (address) {
        return heap.getPrev(id);
    }

    function getNext(address id) public view returns (address) {
        return heap.getNext(id);
    }
}
