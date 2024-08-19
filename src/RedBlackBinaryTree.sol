// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// A Solidity Red-Black Tree library to store and maintain a sorted data structure in a Red-Black binary search tree,
// with O(log 2n) insert, remove and search time (and gas, approximately) based on https://github.com/rob-Hitchens/OrderStatisticsTree
// Copyright (c) Rob Hitchens. the MIT License.
// Significant portions from BokkyPooBahsRedBlackTreeLibrary,
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

/// @title Red Black Binary Tree.
/// @author Morpho Labs.
/// @custom:contact security@morpho.xyz
/// @notice Basic implementation of a Red Balck Binary Tree.
library RedBlackBinaryTree {
    /* STRUCTS */

    struct Node {
        uint256 parent; // The parent node of the current node.
        uint256 leftChild; // The left child of the current node.
        uint256 rightChild; // The right child of the current node.
        bool red; // Whether the current node is red or black.
        address[] keys; // The keys sharing the value of the node.
        mapping(address => uint256) keyMap; // Maps the keys to their index in `keys`.
    }

    struct Tree {
        uint256 root; // Root node.
        mapping(uint256 => Node) nodes; // Maps value to Node.
        mapping(address => uint256) keyToValue; // Maps key to its value.
    }

    /* INTERNAL */

    /// @dev Returns the smallest value in the tree `self`.
    /// @param self The tree to search in.
    function first(Tree storage self) internal view returns (uint256 value) {
        value = self.root;
        if (value == 0) return 0;
        while (self.nodes[value].leftChild != 0) {
            value = self.nodes[value].leftChild;
        }
    }

    /// @dev Returns the highest value in the tree `self`.
    /// @param self The tree to search in.
    function last(Tree storage self) internal view returns (uint256 value) {
        value = self.root;
        if (value == 0) return 0;
        while (self.nodes[value].rightChild != 0) {
            value = self.nodes[value].rightChild;
        }
    }

    /// @dev Returns the next value below `value`.
    /// @param self The tree to search in.
    /// @param value The value to search after.
    function next(Tree storage self, uint256 value) internal view returns (uint256 cursor) {
        require(value != 0, "RBBT(1):start-value=0");
        if (self.nodes[value].rightChild != 0) {
            cursor = _subTreeMin(self, self.nodes[value].rightChild);
        } else {
            cursor = self.nodes[value].parent;
            while (cursor != 0 && value == self.nodes[cursor].rightChild) {
                value = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /// @dev Returns the previous value above `value`.
    /// @param self The tree to search in.
    /// @param value The value to search before.
    function prev(Tree storage self, uint256 value) internal view returns (uint256 cursor) {
        require(value != 0, "RBBT(2):start-value=0");
        if (self.nodes[value].leftChild != 0) {
            cursor = _subTreeMax(self, self.nodes[value].leftChild);
        } else {
            cursor = self.nodes[value].parent;
            while (cursor != 0 && value == self.nodes[cursor].leftChild) {
                value = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /// @dev Returns whether the `value` exists in the tree or not.
    /// @param self The tree to search in.
    /// @param value The value to search.
    /// @return Whether the `value` exists in the tree or not.
    function exists(Tree storage self, uint256 value) internal view returns (bool) {
        if (value == 0) return false;
        if (value == self.root) return true;
        if (self.nodes[value].parent != 0) return true;
        return false;
    }

    /// @dev Returns whether the `key` exists in the tree or not.
    /// @param self The tree to search in.
    /// @param key The key to search.
    /// @return Whether the `key` exists in the tree or not.
    function keyExists(Tree storage self, address key) internal view returns (bool) {
        return self.keyToValue[key] != 0;
    }

    /// @dev Returns the `key` that has the given `value` at the specified `index`.
    /// @param self The tree to search in.
    /// @param value The value to search.
    /// @param index The index in the list of keys.
    /// @return The key address.
    function valueKeyAtIndex(Tree storage self, uint256 value, uint256 index) internal view returns (address) {
        require(exists(self, value), "RBBT:value-not-exist");
        return self.nodes[value].keys[index];
    }

    /// @dev Returns the number of keys in a given node.
    /// @param self The tree to search in.
    /// @param value The value of the node to search for.
    /// @return The number of keys in this node.
    function getNumberOfKeysAtValue(Tree storage self, uint256 value) internal view returns (uint256) {
        if (!exists(self, value)) return 0;
        return self.nodes[value].keys.length;
    }

    /// @dev Returns whether or not there is any key in the tree.
    /// @param self The tree to search in.
    /// @return Whether or not a key exist in the tree.
    function isNotEmpty(Tree storage self) internal view returns (bool) {
        return self.nodes[self.root].keys.length > 0;
    }

    /// @dev Inserts the `key` with `value` in the tree.
    /// @param self The tree in which to add the (key, value) pair.
    /// @param key The key to add.
    /// @param value The value to add.
    function insert(Tree storage self, address key, uint256 value) internal {
        require(value != 0, "RBBT:value-cannot-be-0");
        require(self.keyToValue[key] == 0, "RBBT:account-already-in");
        self.keyToValue[key] = value;
        uint256 cursor;
        uint256 probe = self.root;
        while (probe != 0) {
            cursor = probe;
            if (value < probe) {
                probe = self.nodes[probe].leftChild;
            } else if (value > probe) {
                probe = self.nodes[probe].rightChild;
            } else if (value == probe) {
                self.nodes[probe].keys.push(key);
                self.nodes[probe].keyMap[key] = self.nodes[probe].keys.length - 1;
                return;
            }
        }
        Node storage nValue = self.nodes[value];
        nValue.parent = cursor;
        nValue.leftChild = 0;
        nValue.rightChild = 0;
        nValue.red = true;
        nValue.keys.push(key);
        nValue.keyMap[key] = nValue.keys.length - 1;
        if (cursor == 0) {
            self.root = value;
        } else if (value < cursor) {
            self.nodes[cursor].leftChild = value;
        } else {
            self.nodes[cursor].rightChild = value;
        }
        _insertFixup(self, value);
    }

    /// @dev Removes the `key` in the tree and its related value if no-one shares the same value.
    /// @param self The tree in which to remove the (key, value) pair.
    /// @param key The key to remove.
    function remove(Tree storage self, address key) internal {
        require(self.keyToValue[key] != 0, "RBBT:account-not-exist");
        uint256 value = self.keyToValue[key];
        self.keyToValue[key] = 0;
        Node storage nValue = self.nodes[value];
        uint256 rowToDelete = nValue.keyMap[key];
        nValue.keys[rowToDelete] = nValue.keys[nValue.keys.length - 1];
        nValue.keys.pop();
        uint256 probe;
        uint256 cursor;
        if (nValue.keys.length == 0) {
            if (self.nodes[value].leftChild == 0 || self.nodes[value].rightChild == 0) {
                cursor = value;
            } else {
                cursor = self.nodes[value].rightChild;
                while (self.nodes[cursor].leftChild != 0) {
                    cursor = self.nodes[cursor].leftChild;
                }
            }
            if (self.nodes[cursor].leftChild != 0) {
                probe = self.nodes[cursor].leftChild;
            } else {
                probe = self.nodes[cursor].rightChild;
            }
            uint256 cursorParent = self.nodes[cursor].parent;
            self.nodes[probe].parent = cursorParent;
            if (cursorParent != 0) {
                if (cursor == self.nodes[cursorParent].leftChild) {
                    self.nodes[cursorParent].leftChild = probe;
                } else {
                    self.nodes[cursorParent].rightChild = probe;
                }
            } else {
                self.root = probe;
            }
            bool doFixup = !self.nodes[cursor].red;
            if (cursor != value) {
                _replaceParent(self, cursor, value);
                self.nodes[cursor].leftChild = self.nodes[value].leftChild;
                self.nodes[self.nodes[cursor].leftChild].parent = cursor;
                self.nodes[cursor].rightChild = self.nodes[value].rightChild;
                self.nodes[self.nodes[cursor].rightChild].parent = cursor;
                self.nodes[cursor].red = self.nodes[value].red;
                (cursor, value) = (value, cursor);
            }
            if (doFixup) {
                _removeFixup(self, probe);
            }
            delete self.nodes[cursor];
        }
    }

    /* PRIVATE */

    /// @dev Returns the minimum of the subtree beginning at a given node.
    /// @param self The tree to search in.
    /// @param value The value of the node to start at.
    function _subTreeMin(Tree storage self, uint256 value) private view returns (uint256) {
        while (self.nodes[value].leftChild != 0) {
            value = self.nodes[value].leftChild;
        }
        return value;
    }

    /// @dev Returns the maximum of the subtree beginning at a given node.
    /// @param self The tree to search in.
    /// @param value The value of the node to start at.
    function _subTreeMax(Tree storage self, uint256 value) private view returns (uint256) {
        while (self.nodes[value].rightChild != 0) {
            value = self.nodes[value].rightChild;
        }
        return value;
    }

    /// @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's rightChild child), C (B's leftChild child).
    ///          After leftChild rotation: B (Root), A (B's leftChild child), C (B's rightChild child).
    /// @param self The tree to apply the rotation to.
    /// @param value The value of the node to rotate.
    function _rotateLeft(Tree storage self, uint256 value) private {
        uint256 cursor = self.nodes[value].rightChild;
        uint256 parent = self.nodes[value].parent;
        uint256 cursorLeft = self.nodes[cursor].leftChild;
        self.nodes[value].rightChild = cursorLeft;
        if (cursorLeft != 0) {
            self.nodes[cursorLeft].parent = value;
        }
        self.nodes[cursor].parent = parent;
        if (parent == 0) {
            self.root = cursor;
        } else if (value == self.nodes[parent].leftChild) {
            self.nodes[parent].leftChild = cursor;
        } else {
            self.nodes[parent].rightChild = cursor;
        }
        self.nodes[cursor].leftChild = value;
        self.nodes[value].parent = cursor;
    }

    /// @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's leftChild child), C (B's rightChild child).
    ///          After rightChild rotation: B (Root), A (B's rightChild child), C (B's leftChild child).
    /// @param self The tree to apply the rotation to.
    /// @param value The value of the node to rotate.
    function _rotateRight(Tree storage self, uint256 value) private {
        uint256 cursor = self.nodes[value].leftChild;
        uint256 parent = self.nodes[value].parent;
        uint256 cursorRight = self.nodes[cursor].rightChild;
        self.nodes[value].leftChild = cursorRight;
        if (cursorRight != 0) {
            self.nodes[cursorRight].parent = value;
        }
        self.nodes[cursor].parent = parent;
        if (parent == 0) {
            self.root = cursor;
        } else if (value == self.nodes[parent].rightChild) {
            self.nodes[parent].rightChild = cursor;
        } else {
            self.nodes[parent].leftChild = cursor;
        }
        self.nodes[cursor].rightChild = value;
        self.nodes[value].parent = cursor;
    }

    /// @dev Makes sure there is no violation of the tree properties after an insertion.
    /// @param self The tree to check and correct if needed.
    /// @param value The value that was inserted.
    function _insertFixup(Tree storage self, uint256 value) private {
        uint256 cursor;
        while (value != self.root && self.nodes[self.nodes[value].parent].red) {
            uint256 valueParent = self.nodes[value].parent;
            if (valueParent == self.nodes[self.nodes[valueParent].parent].leftChild) {
                cursor = self.nodes[self.nodes[valueParent].parent].rightChild;
                if (self.nodes[cursor].red) {
                    self.nodes[valueParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    value = self.nodes[valueParent].parent;
                } else {
                    if (value == self.nodes[valueParent].rightChild) {
                        value = valueParent;
                        _rotateLeft(self, value);
                    }
                    valueParent = self.nodes[value].parent;
                    self.nodes[valueParent].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    _rotateRight(self, self.nodes[valueParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[valueParent].parent].leftChild;
                if (self.nodes[cursor].red) {
                    self.nodes[valueParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    value = self.nodes[valueParent].parent;
                } else {
                    if (value == self.nodes[valueParent].leftChild) {
                        value = valueParent;
                        _rotateRight(self, value);
                    }
                    valueParent = self.nodes[value].parent;
                    self.nodes[valueParent].red = false;
                    self.nodes[self.nodes[valueParent].parent].red = true;
                    _rotateLeft(self, self.nodes[valueParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    /// @dev Replace the parent of A by B's parent.
    /// @param self The tree to work with.
    /// @param a The node that will get the new parents.
    /// @param b The node that gives its parent.
    function _replaceParent(Tree storage self, uint256 a, uint256 b) private {
        uint256 bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == 0) {
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
    /// @param value The probe value of the function remove.
    function _removeFixup(Tree storage self, uint256 value) private {
        uint256 cursor;
        while (value != self.root && !self.nodes[value].red) {
            uint256 valueParent = self.nodes[value].parent;
            if (value == self.nodes[valueParent].leftChild) {
                cursor = self.nodes[valueParent].rightChild;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[valueParent].red = true;
                    _rotateLeft(self, valueParent);
                    cursor = self.nodes[valueParent].rightChild;
                }
                if (!self.nodes[self.nodes[cursor].leftChild].red && !self.nodes[self.nodes[cursor].rightChild].red) {
                    self.nodes[cursor].red = true;
                    value = valueParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].rightChild].red) {
                        self.nodes[self.nodes[cursor].leftChild].red = false;
                        self.nodes[cursor].red = true;
                        _rotateRight(self, cursor);
                        cursor = self.nodes[valueParent].rightChild;
                    }
                    self.nodes[cursor].red = self.nodes[valueParent].red;
                    self.nodes[valueParent].red = false;
                    self.nodes[self.nodes[cursor].rightChild].red = false;
                    _rotateLeft(self, valueParent);
                    value = self.root;
                }
            } else {
                cursor = self.nodes[valueParent].leftChild;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[valueParent].red = true;
                    _rotateRight(self, valueParent);
                    cursor = self.nodes[valueParent].leftChild;
                }
                if (!self.nodes[self.nodes[cursor].rightChild].red && !self.nodes[self.nodes[cursor].leftChild].red) {
                    self.nodes[cursor].red = true;
                    value = valueParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].leftChild].red) {
                        self.nodes[self.nodes[cursor].rightChild].red = false;
                        self.nodes[cursor].red = true;
                        _rotateLeft(self, cursor);
                        cursor = self.nodes[valueParent].leftChild;
                    }
                    self.nodes[cursor].red = self.nodes[valueParent].red;
                    self.nodes[valueParent].red = false;
                    self.nodes[self.nodes[cursor].leftChild].red = false;
                    _rotateRight(self, valueParent);
                    value = self.root;
                }
            }
        }
        self.nodes[value].red = false;
    }
}
