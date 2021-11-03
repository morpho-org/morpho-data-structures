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
        tree.keyExists(_id);
    }

    function last() external view {
        tree.last();
    }

    function returnLast() external view returns (address) {
        address key = tree.last();
        return key;
    }

    function returnFirst() external view returns (address) {
        address key = tree.first();
        return key;
    }

    function returnNext(address _key) external view returns (address) {
        address next = tree.next(_key);
        return next;
    }

    function returnKeyToValue(address _key) external view returns (uint256) {
        uint256 value = tree.keyToValue[_key];
        return value;
    }
}
