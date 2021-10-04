// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

// A Solidity Red-Black Tree library to store and maintain a sorted data structure in a Red-Black binary search tree,
// with O(log 2n) insert, remove and search time (and gas, approximately) based on https://github.com/rob-Hitchens/OrderStatisticsTree
// Copyright (c) Rob Hitchens. the MIT License.
// Significant portions from BokkyPooBahsRedBlackTreeLibrary,
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

library RedBlackBinaryTree {
    struct Node {
        uint256 parent;
        uint256 left;
        uint256 right;
        uint256 count;
        bool red;
        address[] keys;
        mapping(address => uint256) keyMap;
    }

    struct Tree {
        uint256 root;
        mapping(uint256 => Node) nodes;
        mapping(address => uint256) keyToValue;
        mapping(address => bool) isIn;
    }

    function first(Tree storage _self) public view returns (uint256 value) {
        value = _self.root;
        if (value == 0) return 0;
        while (_self.nodes[value].left != 0) {
            value = _self.nodes[value].left;
        }
    }

    function last(Tree storage _self) public view returns (uint256 value) {
        value = _self.root;
        if (value == 0) return 0;
        while (_self.nodes[value].right != 0) {
            value = _self.nodes[value].right;
        }
    }

    function next(Tree storage _self, uint256 _value) public view returns (uint256 cursor) {
        require(_value != 0, "RBBT(401):start-_value=0");
        if (_self.nodes[_value].right != 0) {
            cursor = treeMinimum(_self, _self.nodes[_value].right);
        } else {
            cursor = _self.nodes[_value].parent;
            while (cursor != 0 && _value == _self.nodes[cursor].right) {
                _value = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    function prev(Tree storage _self, uint256 _value) public view returns (uint256 cursor) {
        require(_value != 0, "RBBT(402):start-_value=0");
        if (_self.nodes[_value].left != 0) {
            cursor = treeMaximum(_self, _self.nodes[_value].left);
        } else {
            cursor = _self.nodes[_value].parent;
            while (cursor != 0 && _value == _self.nodes[cursor].left) {
                _value = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    function exists(Tree storage _self, uint256 _value) public view returns (bool) {
        if (_value == 0) return false;
        if (_value == _self.root) return true;
        if (_self.nodes[_value].parent != 0) return true;
        return false;
    }

    function keyExists(Tree storage _self, address _key) public view returns (bool) {
        return _self.isIn[_key];
    }

    function getNodeCount(Tree storage _self, uint256 value) public view returns (uint256) {
        Node storage gn = _self.nodes[value];
        return gn.keys.length + gn.count;
    }

    function valueKeyAtIndex(
        Tree storage _self,
        uint256 _value,
        uint256 _index
    ) public view returns (address _key) {
        require(exists(_self, _value), "RBBT(404):value-not-exist");
        return _self.nodes[_value].keys[_index];
    }

    function count(Tree storage _self) public view returns (uint256) {
        return getNodeCount(_self, _self.root);
    }

    function insert(
        Tree storage _self,
        address _key,
        uint256 _value
    ) public {
        require(_value != 0, "RBBT(405):value-cannot-be-0");
        require(!_self.isIn[_key], "RBBT:account-already-in");
        _self.isIn[_key] = true;
        _self.keyToValue[_key] = _value;
        uint256 cursor;
        uint256 probe = _self.root;
        while (probe != 0) {
            cursor = probe;
            if (_value < probe) {
                probe = _self.nodes[probe].left;
            } else if (_value > probe) {
                probe = _self.nodes[probe].right;
            } else if (_value == probe) {
                _self.nodes[probe].keys.push(_key);
                _self.nodes[probe].keyMap[_key] = _self.nodes[probe].keys.length - 1;
                return;
            }
            _self.nodes[cursor].count++;
        }
        Node storage nValue = _self.nodes[_value];
        nValue.parent = cursor;
        nValue.left = 0;
        nValue.right = 0;
        nValue.red = true;
        nValue.keys.push(_key);
        nValue.keyMap[_key] = nValue.keys.length - 1;
        if (cursor == 0) {
            _self.root = _value;
        } else if (_value < cursor) {
            _self.nodes[cursor].left = _value;
        } else {
            _self.nodes[cursor].right = _value;
        }
        insertFixup(_self, _value);
    }

    function remove(Tree storage _self, address _key) public {
        require(_self.isIn[_key], "RBBT:account-not-exist");
        _self.isIn[_key] = false;
        uint256 value = _self.keyToValue[_key];
        Node storage nValue = _self.nodes[value];
        uint256 rowToDelete = nValue.keyMap[_key];
        nValue.keys[rowToDelete] = nValue.keys[nValue.keys.length - 1];
        nValue.keyMap[_key] = rowToDelete;
        nValue.keys.pop();
        uint256 probe;
        uint256 cursor;
        if (nValue.keys.length == 0) {
            if (_self.nodes[value].left == 0 || _self.nodes[value].right == 0) {
                cursor = value;
            } else {
                cursor = _self.nodes[value].right;
                while (_self.nodes[cursor].left != 0) {
                    cursor = _self.nodes[cursor].left;
                }
            }
            if (_self.nodes[cursor].left != 0) {
                probe = _self.nodes[cursor].left;
            } else {
                probe = _self.nodes[cursor].right;
            }
            uint256 cursorParent = _self.nodes[cursor].parent;
            _self.nodes[probe].parent = cursorParent;
            if (cursorParent != 0) {
                if (cursor == _self.nodes[cursorParent].left) {
                    _self.nodes[cursorParent].left = probe;
                } else {
                    _self.nodes[cursorParent].right = probe;
                }
            } else {
                _self.root = probe;
            }
            bool doFixup = !_self.nodes[cursor].red;
            if (cursor != value) {
                replaceParent(_self, cursor, value);
                _self.nodes[cursor].left = _self.nodes[value].left;
                _self.nodes[_self.nodes[cursor].left].parent = cursor;
                _self.nodes[cursor].right = _self.nodes[value].right;
                _self.nodes[_self.nodes[cursor].right].parent = cursor;
                _self.nodes[cursor].red = _self.nodes[value].red;
                (cursor, value) = (value, cursor);
                fixCountRecurse(_self, value);
            }
            if (doFixup) {
                removeFixup(_self, probe);
            }
            fixCountRecurse(_self, cursorParent);
            delete _self.nodes[cursor];
        }
    }

    function fixCountRecurse(Tree storage _self, uint256 _value) private {
        while (_value != 0) {
            _self.nodes[_value].count =
                getNodeCount(_self, _self.nodes[_value].left) +
                getNodeCount(_self, _self.nodes[_value].right);
            _value = _self.nodes[_value].parent;
        }
    }

    function treeMinimum(Tree storage _self, uint256 _value) private view returns (uint256) {
        while (_self.nodes[_value].left != 0) {
            _value = _self.nodes[_value].left;
        }
        return _value;
    }

    function treeMaximum(Tree storage _self, uint256 _value) private view returns (uint256) {
        while (_self.nodes[_value].right != 0) {
            _value = _self.nodes[_value].right;
        }
        return _value;
    }

    function rotateLeft(Tree storage _self, uint256 _value) private {
        uint256 cursor = _self.nodes[_value].right;
        uint256 parent = _self.nodes[_value].parent;
        uint256 cursorLeft = _self.nodes[cursor].left;
        _self.nodes[_value].right = cursorLeft;
        if (cursorLeft != 0) {
            _self.nodes[cursorLeft].parent = _value;
        }
        _self.nodes[cursor].parent = parent;
        if (parent == 0) {
            _self.root = cursor;
        } else if (_value == _self.nodes[parent].left) {
            _self.nodes[parent].left = cursor;
        } else {
            _self.nodes[parent].right = cursor;
        }
        _self.nodes[cursor].left = _value;
        _self.nodes[_value].parent = cursor;
        _self.nodes[_value].count =
            getNodeCount(_self, _self.nodes[_value].left) +
            getNodeCount(_self, _self.nodes[_value].right);
        _self.nodes[cursor].count =
            getNodeCount(_self, _self.nodes[cursor].left) +
            getNodeCount(_self, _self.nodes[cursor].right);
    }

    function rotateRight(Tree storage _self, uint256 _value) private {
        uint256 cursor = _self.nodes[_value].left;
        uint256 parent = _self.nodes[_value].parent;
        uint256 cursorRight = _self.nodes[cursor].right;
        _self.nodes[_value].left = cursorRight;
        if (cursorRight != 0) {
            _self.nodes[cursorRight].parent = _value;
        }
        _self.nodes[cursor].parent = parent;
        if (parent == 0) {
            _self.root = cursor;
        } else if (_value == _self.nodes[parent].right) {
            _self.nodes[parent].right = cursor;
        } else {
            _self.nodes[parent].left = cursor;
        }
        _self.nodes[cursor].right = _value;
        _self.nodes[_value].parent = cursor;
        _self.nodes[_value].count =
            getNodeCount(_self, _self.nodes[_value].left) +
            getNodeCount(_self, _self.nodes[_value].right);
        _self.nodes[cursor].count =
            getNodeCount(_self, _self.nodes[cursor].left) +
            getNodeCount(_self, _self.nodes[cursor].right);
    }

    function insertFixup(Tree storage _self, uint256 _value) private {
        uint256 cursor;
        while (_value != _self.root && _self.nodes[_self.nodes[_value].parent].red) {
            uint256 valueParent = _self.nodes[_value].parent;
            if (valueParent == _self.nodes[_self.nodes[valueParent].parent].left) {
                cursor = _self.nodes[_self.nodes[valueParent].parent].right;
                if (_self.nodes[cursor].red) {
                    _self.nodes[valueParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    _value = _self.nodes[valueParent].parent;
                } else {
                    if (_value == _self.nodes[valueParent].right) {
                        _value = valueParent;
                        rotateLeft(_self, _value);
                    }
                    valueParent = _self.nodes[_value].parent;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    rotateRight(_self, _self.nodes[valueParent].parent);
                }
            } else {
                cursor = _self.nodes[_self.nodes[valueParent].parent].left;
                if (_self.nodes[cursor].red) {
                    _self.nodes[valueParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    _value = _self.nodes[valueParent].parent;
                } else {
                    if (_value == _self.nodes[valueParent].left) {
                        _value = valueParent;
                        rotateRight(_self, _value);
                    }
                    valueParent = _self.nodes[_value].parent;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    rotateLeft(_self, _self.nodes[valueParent].parent);
                }
            }
        }
        _self.nodes[_self.root].red = false;
    }

    function replaceParent(
        Tree storage _self,
        uint256 _a,
        uint256 _b
    ) private {
        uint256 bParent = _self.nodes[_b].parent;
        _self.nodes[_a].parent = bParent;
        if (bParent == 0) {
            _self.root = _a;
        } else {
            if (_b == _self.nodes[bParent].left) {
                _self.nodes[bParent].left = _a;
            } else {
                _self.nodes[bParent].right = _a;
            }
        }
    }

    function removeFixup(Tree storage _self, uint256 _value) private {
        uint256 cursor;
        while (_value != _self.root && !_self.nodes[_value].red) {
            uint256 valueParent = _self.nodes[_value].parent;
            if (_value == _self.nodes[valueParent].left) {
                cursor = _self.nodes[valueParent].right;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[valueParent].red = true;
                    rotateLeft(_self, valueParent);
                    cursor = _self.nodes[valueParent].right;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].left].red &&
                    !_self.nodes[_self.nodes[cursor].right].red
                ) {
                    _self.nodes[cursor].red = true;
                    _value = valueParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].right].red) {
                        _self.nodes[_self.nodes[cursor].left].red = false;
                        _self.nodes[cursor].red = true;
                        rotateRight(_self, cursor);
                        cursor = _self.nodes[valueParent].right;
                    }
                    _self.nodes[cursor].red = _self.nodes[valueParent].red;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[cursor].right].red = false;
                    rotateLeft(_self, valueParent);
                    _value = _self.root;
                }
            } else {
                cursor = _self.nodes[valueParent].left;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[valueParent].red = true;
                    rotateRight(_self, valueParent);
                    cursor = _self.nodes[valueParent].left;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].right].red &&
                    !_self.nodes[_self.nodes[cursor].left].red
                ) {
                    _self.nodes[cursor].red = true;
                    _value = valueParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].left].red) {
                        _self.nodes[_self.nodes[cursor].right].red = false;
                        _self.nodes[cursor].red = true;
                        rotateLeft(_self, cursor);
                        cursor = _self.nodes[valueParent].left;
                    }
                    _self.nodes[cursor].red = _self.nodes[valueParent].red;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[cursor].left].red = false;
                    rotateRight(_self, valueParent);
                    _value = _self.root;
                }
            }
        }
        _self.nodes[_value].red = false;
    }
}
