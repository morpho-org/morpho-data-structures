// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "hardhat/console.sol";
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

    function addTail(address _id, uint256 _value) external {
        list.addTail(_id, _value);
    }

    function getNext(address _id) external view {
        uint256 gasBefore = gasleft();
        list.getNext(_id);
        console.log("getNext", gasBefore - gasleft());
    }

    function getHead() external view {
        uint256 gasBefore = gasleft();
        list.getHead();
        console.log("getHead", gasBefore - gasleft());
    }

    function length() external view {
        uint256 gasBefore = gasleft();
        list.length();
        console.log("length", gasBefore - gasleft());
    }
}
