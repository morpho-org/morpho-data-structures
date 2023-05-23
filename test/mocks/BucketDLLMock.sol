// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BucketDLL} from "src/BucketDLL.sol";

library BucketDLLMock {
    /* INTERNAL */

    function remove(BucketDLL.List storage list, address id) internal returns (bool) {
        return BucketDLL.remove(list, id);
    }

    function insert(BucketDLL.List storage list, address id, bool head) internal returns (bool) {
        return BucketDLL.insert(list, id, head);
    }

    function getNext(BucketDLL.List storage list, address id) internal view returns (address) {
        return BucketDLL.getNext(list, id);
    }

    function getHead(BucketDLL.List storage list) internal view returns (address) {
        return list.accounts[address(0)].next;
    }

    function getPrev(BucketDLL.List storage list, address id) internal view returns (address) {
        return list.accounts[id].prev;
    }

    function getTail(BucketDLL.List storage list) internal view returns (address) {
        return list.accounts[address(0)].prev;
    }
}
