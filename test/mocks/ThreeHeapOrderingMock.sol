// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/ThreeHeapOrdering.sol";
import "./IHeapOrderingMock.sol";

contract ThreeHeapOrderingMock is IHeapOrderingMock {
    using ThreeHeapOrdering for ThreeHeapOrdering.HeapArray;

    ThreeHeapOrdering.HeapArray internal heap;

    function accountsValue(uint256 _index) external view returns (uint256) {
        return heap.accounts[_index].value;
    }

    function accountsId(uint256 _index) external view returns (address) {
        return heap.accounts[_index].id;
    }

    function indexOf(address _id) external view returns (uint256) {
        return heap.indexOf[_id];
    }

    function update(
        address _id,
        uint256 _formerValue,
        uint256 _newValue,
        uint256 _maxSortedUsers
    ) external {
        heap.update(_id, _formerValue, _newValue, _maxSortedUsers);
    }

    function length() external view returns (uint256) {
        return heap.length();
    }

    function size() external view returns (uint256) {
        return heap.size;
    }

    function getValueOf(address _id) external view returns (uint256) {
        return heap.getValueOf(_id);
    }

    function getHead() external view returns (address) {
        return heap.getHead();
    }

    function getTail() external view returns (address) {
        return heap.getTail();
    }

    function getPrev(address _id) external view returns (address) {
        return heap.getPrev(_id);
    }

    function getNext(address _id) external view returns (address) {
        return heap.getNext(_id);
    }
}
