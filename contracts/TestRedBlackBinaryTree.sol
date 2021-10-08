// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "hardhat/console.sol";
import "./RedBlackBinaryTree.sol";

contract TestRedBlackBinaryTree {
    using RedBlackBinaryTree for RedBlackBinaryTree.Tree;

    RedBlackBinaryTree.Tree public tree;

    function insert(address _id, uint256 _value) external {
        tree.insert(_id, _value);
    }

    function remove(address _id) external {
        tree.remove(_id);
    }

    function keyExists(address _id) external view {
        uint256 gasBefore = gasleft();
        tree.keyExists(_id);
        console.log("keyExists", gasBefore - gasleft());
    }

    function last() external view {
        uint256 gasBefore = gasleft();
        tree.last();
        console.log("last", gasBefore - gasleft());
    }

    function getNumberOfKeysAtValue(uint256 _value) external view {
        uint256 gasBefore = gasleft();
        tree.getNumberOfKeysAtValue(_value);
        console.log("getNumberOfKeysAtValue", gasBefore - gasleft());
    }

    function valueKeyAtIndex(uint256 _value, uint256 _index) external view {
        uint256 gasBefore = gasleft();
        tree.valueKeyAtIndex(_value, _index);
        console.log("valueKeyAtIndex", gasBefore - gasleft());
    }

    function returnLast() external view returns (uint256) {
        return (tree.last());
    }

    function returnFirst() external view returns (uint256) {
        return (tree.first());
    }

    function returnGetNumberOfKeysAtValue(uint256 _value) external view returns (uint256) {
        return (tree.getNumberOfKeysAtValue(_value));
    }

    function returnValueKeyAtIndex(uint256 _value, uint256 _index) external view returns (address) {
        return (tree.valueKeyAtIndex(_value, _index));
    }

    function returnNext(uint256 _value) external view returns (uint256) {
        return (tree.next(_value));
    }
}
