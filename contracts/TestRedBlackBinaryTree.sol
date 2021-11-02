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
}
