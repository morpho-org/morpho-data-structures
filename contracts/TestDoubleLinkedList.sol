// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./DoubleLinkedList.sol";

contract TestDoubleLinkedList {
    using DoubleLinkedList for DoubleLinkedList.List;

    DoubleLinkedList.List public list;

    function insertSorted(address _id, uint256 _value) external {
        list.insertSorted(_id, _value);
    }

    function remove(address _id) external {
        list.remove(_id);
    }

    function getHead() external view returns (address) {
        return list.getHead();
    }

    function length() external view returns (uint256) {
        return list.length();
    }
}
