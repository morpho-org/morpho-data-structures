// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

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

    function keyExists(address _id) external view returns (bool) {
        return tree.keyExists(_id);
    }

    function last() external view returns (uint256) {
        return tree.last();
    }

    function getNodeCount(uint256 _value) external view returns (uint256) {
        return tree.getNodeCount(_value);
    }

    function valueKeyAtIndex(uint256 _value, uint256 _index) external view returns (address) {
        return tree.valueKeyAtIndex(_value, _index);
    }

    function count() external view returns (uint256) {
        return tree.count();
    }
}
