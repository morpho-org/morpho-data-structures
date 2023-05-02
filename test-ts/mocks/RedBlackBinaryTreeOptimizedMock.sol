// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/RedBlackBinaryTreeOptimized.sol";

contract RedBlackBinaryTreeOptimizedMock {
    using RedBlackBinaryTreeOptimized for RedBlackBinaryTreeOptimized.Tree;

    RedBlackBinaryTreeOptimized.Tree public tree;

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

    function returnLast() external view returns (address) {
        return tree.last();
    }

    function first() external view returns (address) {
        return tree.first();
    }

    function next(address _key) external view returns (address) {
        return tree.next(_key);
    }

    function returnKeyToValue(address _key) external view returns (uint256) {
        return tree.keyToValue[_key];
    }
}
