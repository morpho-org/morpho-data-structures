// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// A Solidity Red-Black Tree library to store and maintain a sorted data structure in a Red-Black binary search tree,
// with O(log 2n) insert, remove and search time (and gas, approximately) based on https://github.com/rob-Hitchens/OrderStatisticsTree
// Copyright (c) Rob Hitchens. the MIT License.
// Significant portions from BokkyPooBahsRedBlackTreeLibrary,
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

/// @title Red Black Binary Tree Optimized.
/// @author Morpho Labs.
/// @custom:contact security@morpho.xyz
/// @notice Optimized implementation of a Red Balck Binary Tree.
library RedBlackBinaryTreeOptimized {
    /* STRUCTS */

    struct Node {
        address parent; // The parent node of the current node.
        address leftChild; // The left child of the current node.
        address rightChild; // The right child of the current node.
        bool red; // Whether the current node is red or black.
    }

    struct Tree {
        address root; // Address of the root node
        mapping(address => Node) nodes; // Map user's address to node
        mapping(address => uint256) keyToValue; // Maps key to its value
    }

    /* INTERNAL */

    /// @dev Returns the address of the smallest value in the tree `self`.
    /// @param self The tree to search in.
    function first(Tree storage self) internal view returns (address key) {
        key = self.root;
        if (key == address(0)) return address(0);
        while (self.nodes[key].leftChild != address(0)) {
            key = self.nodes[key].leftChild;
        }
    }

    /// @dev Returns the address of the highest value in the tree `self`.
    /// @param self The tree to search in.
    function last(Tree storage self) internal view returns (address key) {
        key = self.root;
        if (key == address(0)) return address(0);
        while (self.nodes[key].rightChild != address(0)) {
            key = self.nodes[key].rightChild;
        }
    }

    /// @dev Returns the address of the next user after `key`.
    /// @param self The tree to search in.
    /// @param key The address to search after.
    function next(Tree storage self, address key) internal view returns (address cursor) {
        require(key != address(0), "RBBT(1):key-is-nul-address");
        if (self.nodes[key].rightChild != address(0)) {
            cursor = _subTreeMin(self, self.nodes[key].rightChild);
        } else {
            cursor = self.nodes[key].parent;
            while (cursor != address(0) && key == self.nodes[cursor].rightChild) {
                key = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /// @dev Returns the address of the previous user above `key`.
    /// @param self The tree to search in.
    /// @param key The address to search before.
    function prev(Tree storage self, address key) internal view returns (address cursor) {
        require(key != address(0), "RBBT(2):start-value=0");
        if (self.nodes[key].leftChild != address(0)) {
            cursor = _subTreeMax(self, self.nodes[key].leftChild);
        } else {
            cursor = self.nodes[key].parent;
            while (cursor != address(0) && key == self.nodes[cursor].leftChild) {
                key = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /// @dev Returns whether the `key` exists in the tree or not.
    /// @param self The tree to search in.
    /// @param key The key to search.
    /// @return Whether the `key` exists in the tree or not.
    function keyExists(Tree storage self, address key) internal view returns (bool) {
        return self.keyToValue[key] != 0;
    }

    /// @dev Returns true if A>B according to the order relationship.
    /// @param valueA value for user A.
    /// @param addressA Address for user A.
    /// @param valueB value for user B.
    /// @param addressB Address for user B.
    function compare(uint256 valueA, address addressA, uint256 valueB, address addressB) internal pure returns (bool) {
        if (valueA == valueB) {
            if (addressA > addressB) {
                return true;
            }
        }
        if (valueA > valueB) {
            return true;
        }
        return false;
    }

    /// @dev Returns whether or not there is any key in the tree.
    /// @param self The tree to search in.
    /// @return Whether or not a key exist in the tree.
    function isNotEmpty(Tree storage self) internal view returns (bool) {
        return self.root != address(0);
    }

    /// @dev Inserts the `key` with `value` in the tree.
    /// @param self The tree in which to add the (key, value) pair.
    /// @param key The key to add.
    /// @param value The value to add.
    function insert(Tree storage self, address key, uint256 value) internal {
        require(value != 0, "RBBT:value-cannot-be-0");
        require(self.keyToValue[key] == 0, "RBBT:account-already-in");
        self.keyToValue[key] = value;
        address cursor;
        address probe = self.root;
        while (probe != address(0)) {
            cursor = probe;
            if (compare(self.keyToValue[probe], probe, value, key)) {
                probe = self.nodes[probe].leftChild;
            } else {
                probe = self.nodes[probe].rightChild;
            }
        }
        Node storage nValue = self.nodes[key];
        nValue.parent = cursor;
        nValue.leftChild = address(0);
        nValue.rightChild = address(0);
        nValue.red = true;
        if (cursor == address(0)) {
            self.root = key;
        } else if (compare(self.keyToValue[cursor], cursor, value, key)) {
            self.nodes[cursor].leftChild = key;
        } else {
            self.nodes[cursor].rightChild = key;
        }
        _insertFixup(self, key);
    }

    /// @dev Removes the `key` in the tree and its related value if no-one shares the same value.
    /// @param self The tree in which to remove the (key, value) pair.
    /// @param key The key to remove.
    function remove(Tree storage self, address key) internal {
        require(self.keyToValue[key] != 0, "RBBT:account-not-exist");
        self.keyToValue[key] = 0;
        address probe;
        address cursor;
        if (self.nodes[key].leftChild == address(0) || self.nodes[key].rightChild == address(0)) {
            cursor = key;
        } else {
            cursor = self.nodes[key].rightChild;
            while (self.nodes[cursor].leftChild != address(0)) {
                cursor = self.nodes[cursor].leftChild;
            }
        }
        if (self.nodes[cursor].leftChild != address(0)) {
            probe = self.nodes[cursor].leftChild;
        } else {
            probe = self.nodes[cursor].rightChild;
        }
        address cursorParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = cursorParent;
        if (cursorParent != address(0)) {
            if (cursor == self.nodes[cursorParent].leftChild) {
                self.nodes[cursorParent].leftChild = probe;
            } else {
                self.nodes[cursorParent].rightChild = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            _replaceParent(self, cursor, key);
            self.nodes[cursor].leftChild = self.nodes[key].leftChild;
            self.nodes[self.nodes[cursor].leftChild].parent = cursor;
            self.nodes[cursor].rightChild = self.nodes[key].rightChild;
            self.nodes[self.nodes[cursor].rightChild].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            _removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    /* PRIVATE */

    /// @dev Returns the minimum of the subtree beginning at a given node.
    /// @param self The tree to search in.
    /// @param key The value of the node to start at.
    function _subTreeMin(Tree storage self, address key) private view returns (address) {
        while (self.nodes[key].leftChild != address(0)) {
            key = self.nodes[key].leftChild;
        }
        return key;
    }

    /// @dev Returns the maximum of the subtree beginning at a given node.
    /// @param self The tree to search in.
    /// @param key The address of the node to start at.
    function _subTreeMax(Tree storage self, address key) private view returns (address) {
        while (self.nodes[key].rightChild != address(0)) {
            key = self.nodes[key].rightChild;
        }
        return key;
    }

    /// @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's rightChild child), C (B's leftChild child).
    ///       After leftChild rotation: B (Root), A (B's leftChild child), C (B's rightChild child).
    /// @param self The tree to apply the rotation to.
    /// @param key The address of the node to rotate.
    function _rotateLeft(Tree storage self, address key) private {
        address cursor = self.nodes[key].rightChild;
        address keyParent = self.nodes[key].parent;
        address cursorLeft = self.nodes[cursor].leftChild;
        self.nodes[key].rightChild = cursorLeft;

        if (cursorLeft != address(0)) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == address(0)) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].leftChild) {
            self.nodes[keyParent].leftChild = cursor;
        } else {
            self.nodes[keyParent].rightChild = cursor;
        }
        self.nodes[cursor].leftChild = key;
        self.nodes[key].parent = cursor;
    }

    /// @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's leftChild child), C (B's rightChild child).
    ///          After rightChild rotation: B (Root), A (B's rightChild child), C (B's leftChild child).
    /// @param self The tree to apply the rotation to.
    /// @param key The address of the node to rotate.
    function _rotateRight(Tree storage self, address key) private {
        address cursor = self.nodes[key].leftChild;
        address keyParent = self.nodes[key].parent;
        address cursorRight = self.nodes[cursor].rightChild;
        self.nodes[key].leftChild = cursorRight;
        if (cursorRight != address(0)) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == address(0)) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].rightChild) {
            self.nodes[keyParent].rightChild = cursor;
        } else {
            self.nodes[keyParent].leftChild = cursor;
        }
        self.nodes[cursor].rightChild = key;
        self.nodes[key].parent = cursor;
    }

    /// @dev Makes sure there is no violation of the tree properties after an insertion.
    /// @param self The tree to check and correct if needed.
    /// @param key The address of the user that was inserted.
    function _insertFixup(Tree storage self, address key) private {
        address cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            address keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].leftChild) {
                cursor = self.nodes[self.nodes[keyParent].parent].rightChild;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].rightChild) {
                        key = keyParent;
                        _rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    _rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].leftChild;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].leftChild) {
                        key = keyParent;
                        _rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    _rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    /// @dev Replace the parent of A by B's parent.
    /// @param self The tree to work with.
    /// @param a The node that will get the new parents.
    /// @param b The node that gives its parent.
    function _replaceParent(Tree storage self, address a, address b) private {
        address bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == address(0)) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].leftChild) {
                self.nodes[bParent].leftChild = a;
            } else {
                self.nodes[bParent].rightChild = a;
            }
        }
    }

    /// @dev Makes sure there is no violation of the tree properties after removal.
    /// @param self The tree to check and correct if needed.
    /// @param key The address requested in the function remove.
    function _removeFixup(Tree storage self, address key) private {
        address cursor;
        while (key != self.root && !self.nodes[key].red) {
            address keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].leftChild) {
                cursor = self.nodes[keyParent].rightChild;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    _rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].rightChild;
                }
                if (!self.nodes[self.nodes[cursor].leftChild].red && !self.nodes[self.nodes[cursor].rightChild].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].rightChild].red) {
                        self.nodes[self.nodes[cursor].leftChild].red = false;
                        self.nodes[cursor].red = true;
                        _rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].rightChild;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].rightChild].red = false;
                    _rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].leftChild;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    _rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].leftChild;
                }
                if (!self.nodes[self.nodes[cursor].rightChild].red && !self.nodes[self.nodes[cursor].leftChild].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].leftChild].red) {
                        self.nodes[self.nodes[cursor].rightChild].red = false;
                        self.nodes[cursor].red = true;
                        _rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].leftChild;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].leftChild].red = false;
                    _rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
