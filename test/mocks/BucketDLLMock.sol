// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/BucketDLL.sol";

library BucketDLLMock {
    function remove(BucketDLL.List storage _list, address _id) internal returns (bool) {
        return BucketDLL.remove(_list, _id);
    }

    function insert(
        BucketDLL.List storage _list,
        address _id,
        bool _head
    ) internal returns (bool) {
        return BucketDLL.insert(_list, _id, _head);
    }

    function getNext(BucketDLL.List storage _list, address _id) internal view returns (address) {
        return BucketDLL.getNext(_list, _id);
    }

    function getHead(BucketDLL.List storage _list) internal view returns (address) {
        return _list.accounts[address(0)].next;
    }

    function getPrev(BucketDLL.List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].prev;
    }

    function getTail(BucketDLL.List storage _list) internal view returns (address) {
        return _list.accounts[address(0)].prev;
    }
}
