// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

library DoubleLinkedList {
    /// STRUCTS ///

    error MaxIterationsExceeded();

    struct Account {
        address gtSelf;
        address ltSelf;
        uint256 value;
    }

    struct List {
        mapping(address => Account) accounts;
        address greatest;
        address smallest;
    }

    /// ERRORS ///

    /// @notice Thrown when the account is already inserted in the double linked list.
    error AccountAlreadyInserted();

    /// @notice Thrown when the account to remove does not exist.
    error AccountDoesNotExist();

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// @notice Thrown when the value is zero at insertion.
    error ValueIsZero();

    /// INTERNAL ///

    /// @notice Checks if the list contains an `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return Whether the list contains the account.
    function contains(List storage _list, address _id) internal view returns (bool) {
        return _list.accounts[_id].value > 0;
    }

    /// @notice Returns the `account` linked to `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The value of the account.
    function getValueOf(List storage _list, address _id) internal view returns (uint256) {
        return _list.accounts[_id].value;
    }

    /// @notice Returns the address at the greatest of the `_list`.
    /// @param _list The list to get the greatest.
    /// @return The address of the greatest.
    function getHead(List storage _list) internal view returns (address) {
        return _list.greatest;
    }

    /// @notice Returns the address at the greatest of the `_list`.
    /// @param _list The list to get the greatest.
    /// @return The address of the greatest.
    function getGreatest(List storage _list) internal view returns (address) {
        return _list.greatest;
    }

    /// @notice Returns the address at the smallest of the `_list`.
    /// @param _list The list to get the smallest.
    /// @return The address of the smallest.
    function getTail(List storage _list) internal view returns (address) {
        return _list.smallest;
    }

    /// @notice Returns the address at the smallest of the `_list`.
    /// @param _list The list to get the smallest.
    /// @return The address of the smallest.
    function getSmallest(List storage _list) internal view returns (address) {
        return _list.smallest;
    }

    /// @notice Returns the ltSelf id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the ltSelf account.
    function getNext(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].ltSelf;
    }

    /// @notice Returns the ltSelf id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the ltSelf account.
    function getLessThan(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].ltSelf;
    }

    /// @notice Returns the gtSelf id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the gtSelf account.
    function getPrev(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].gtSelf;
    }

    /// @notice Returns the gtSelf id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the gtSelf account.
    function getGreaterThan(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].gtSelf;
    }

    /// @notice Removes an account of the `_list`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    function remove(List storage _list, address _id) internal {
        if (_list.accounts[_id].value == 0) revert AccountDoesNotExist();
        Account memory account = _list.accounts[_id];

        if (account.gtSelf != address(0)) {
            _list.accounts[account.gtSelf].ltSelf = account.ltSelf;
        } else {
            _list.greatest = account.ltSelf;
        }

        if (account.ltSelf != address(0)) {
            _list.accounts[account.ltSelf].gtSelf = account.gtSelf;
        } else {
            _list.smallest = account.gtSelf;
        }

        delete _list.accounts[_id];
    }

    /// @notice Inserts an account in the `_list` at the right slot based on its `_value`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @param _value The value of the account.
    /// @param _maxIterations The max number of iterations.
    /// @param _hintGT A hint to the node that SHOULD be immediately greater than the value
    /// to be inserted, but MAY not be due to a race condition in transactions.
    function insertSorted(
        List storage _list,
        address _id,
        uint256 _value,
        uint256 _maxIterations,
        address _hintGT
    ) internal {
        if (_value == 0) revert ValueIsZero();
        if (_id == address(0)) revert AddressIsZero();
        if (_list.accounts[_id].value != 0) revert AccountAlreadyInserted();

        if (_list.greatest == address(0) && _list.smallest == address(0)) {
            // Brand new list
            _list.accounts[_id] = Account(address(0), address(0), _value);
            _list.greatest = _id;
            _list.smallest = _id;
            return;
        }
        if (_hintGT == address(0)) {
            _hintGT = _list.greatest;
        }

        uint256 numberOfIterations;
        address gtNewNode = _hintGT;
        bool iterateLower = _list.accounts[gtNewNode].value > _value;
        address iterNode;

        while (numberOfIterations < _maxIterations) {
            iterNode = iterateLower
                ? _list.accounts[gtNewNode].ltSelf
                : _list.accounts[gtNewNode].gtSelf;

            if (iterNode == address(0)) {
                // Reached either end so we're pre/appending
                break;
            }

            if ((_list.accounts[iterNode].value > _value) != iterateLower) {
                // Sign switch indicates we're at the threshold
                if (!iterateLower) {
                    gtNewNode = iterNode;
                }
                break;
            }

            gtNewNode = iterNode;
            unchecked {
                ++numberOfIterations;
            }
        }
        if (numberOfIterations == _maxIterations) {
            revert MaxIterationsExceeded();
        }

        if (iterNode == address(0)) {
            if (iterateLower) {
                // New smallest
                _list.accounts[_id] = Account({
                    gtSelf: _list.smallest,
                    ltSelf: address(0),
                    value: _value
                });
                _list.accounts[_list.smallest].ltSelf = _id;
                _list.smallest = _id;
            } else {
                // New greatest
                _list.accounts[_id] = Account({
                    gtSelf: address(0),
                    ltSelf: _list.greatest,
                    value: _value
                });
                _list.accounts[_list.greatest].gtSelf = _id;
                _list.greatest = _id;
            }
        } else {
            // Stuck in the middle (with you)
            _list.accounts[_id] = Account({
                gtSelf: gtNewNode,
                ltSelf: _list.accounts[gtNewNode].ltSelf,
                value: _value
            });
            _list.accounts[_list.accounts[gtNewNode].ltSelf].gtSelf = _id;
            _list.accounts[gtNewNode].ltSelf = _id;
        }
    }

    /// @notice Equivalent to insertSorted() with the list greatest as _hintGT.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @param _value The value of the account.
    /// @param _maxIterations The max number of iterations.
    function insertSorted(
        List storage _list,
        address _id,
        uint256 _value,
        uint256 _maxIterations
    ) internal {
        insertSorted(_list, _id, _value, _maxIterations, _list.greatest);
    }
}
