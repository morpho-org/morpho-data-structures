// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/RedBlackBinaryTree.sol";

contract RedBlackBinaryTreeMock {
    using RedBlackBinaryTree for RedBlackBinaryTree.Tree;

    RedBlackBinaryTree.Tree public tree;

    function insert(address _id, uint256 _value) external {
        tree.insert(_id, _value);
    }

    function remove(address _id) external {
        tree.remove(_id);
    }

    function keyExists(address _id) external view {
        tree.keyExists(_id);
    }

    function last() external view {
        tree.last();
    }

    function returnLast() external view returns (uint256) {
        return tree.last();
    }

    function first() external view returns (uint256) {
        return tree.first();
    }

    function next(uint256 _value) external view returns (uint256) {
        return tree.next(_value);
    }

    function returnKeyToValue(address _key) external view returns (uint256) {
        return tree.keyToValue[_key];
    }

    function valueKeyAtIndex(uint256 _value, uint256 _index) external view returns (address) {
        return tree.valueKeyAtIndex(_value, _index);
    }

    function getNumberOfKeysAtValue(uint256 _value) external view returns (uint256) {
        return tree.getNumberOfKeysAtValue(_value);
    }
}
