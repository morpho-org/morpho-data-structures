// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../munged-simple/DoubleLinkedList.sol";

contract MockDllSimple {
    using DoubleLinkedList for DoubleLinkedList.List;

    // VERIFICATION INTERFACE

    DoubleLinkedList.List public dll;

    uint256 internal dummy_state_variable;

    function dummy_state_modifying_function() public {
        // to fix a CVL error when only one function is accessible
        dummy_state_variable = 1;
    }

    function getValueOf(address _id) public view returns (uint256) {
        return dll.getValueOf(_id);
    }

    function getHead() public view returns (address) {
        return dll.getHead();
    }

    function getTail() public view returns (address) {
        return dll.getTail();
    }

    function getNext(address _id) public view returns (address) {
        return dll.getNext(_id);
    }

    function getPrev(address _id) public view returns (address) {
        return dll.getPrev(_id);
    }

    function remove(address _id) public {
        dll.remove(_id);
    }

    function insertSorted(address _id, uint256 _value) public {
        dll.insertSorted(_id, _value);
    }

    // SPECIFICATION HELPERS

    function getInsertedAfter() public view returns (address) {
        return dll.insertedAfter;
    }

    function getInsertedBefore() public view returns (address) {
        return dll.insertedBefore;
    }

    function getLength() internal view returns (uint256) {
        uint256 len;
        for (address current = getHead(); current != address(0); current = getNext(current)) {
            len++;
        }
        return len;
    }

    function linkBetween(address _start, address _end) internal view returns (bool, address) {
        if (_start == _end) return (true, address(0));
        for (uint256 maxIter = getLength(); maxIter > 0; maxIter--) {
            address next = getNext(_start);
            if (next == _end) return (true, _start);
            _start = next;
        }
        return (false, address(0));
    }

    function isForwardLinkedBetween(address _start, address _end) public view returns (bool ret) {
        (ret,) = linkBetween(_start, _end);
    }

    function getPreceding(address _end) public view returns (address last) {
        (, last) = linkBetween(getHead(), _end);
    }

    function isDecrSortedFrom(address _start) public view returns (bool) {
        for (uint256 maxIter = getLength(); maxIter > 0; maxIter--) {
            address next = getNext(_start);
            if (next == address(0)) return true;
            if (getValueOf(_start) < getValueOf(next)) return false;
            _start = getNext(_start);
        }
        return true;
    }
}
