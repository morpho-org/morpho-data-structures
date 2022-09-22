// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "@contracts/HeapOrdering.sol";

contract ContractToFuzz is DSTest {
    using HeapOrdering for HeapOrdering.HeapArray;

    uint256 public MAX_SORTED_USERS = 16;
    HeapOrdering.HeapArray public heap;

    /// Functions to fuzz ///

    function update(address _id, uint96 _newValue) public {
        heap.update(_id, heap.getValueOf(_id), _newValue, MAX_SORTED_USERS);
    }

    /// Helpers ///

    function heapLength() public view returns (uint256) {
        return heap.length();
    }

    function accountValue(uint256 i) public view returns (uint256) {
        return heap.accounts[i - 1].value;
    }
}

contract TestHeapInvariant {
    ContractToFuzz public con;

    function setUp() public {
        con = new ContractToFuzz();
    }

    // Rule:
    // For all i in [[0, MAX_SORTED_USERS / 2]],
    // value[i] >= value[2i] and value[i] >= value[2i + 1]
    function invariantHeap() public view {
        uint256 length = con.heapLength();

        for (uint256 i = 1; i < length; ++i) {
            if (
                (!(i * 2 >= length ||
                    i * 2 >= con.MAX_SORTED_USERS() / 2 ||
                    con.accountValue(i) >= con.accountValue(i * 2)) &&
                    (i * 2 + 1 >= length ||
                        i * 2 + 1 >= con.MAX_SORTED_USERS() / 2 ||
                        con.accountValue(i) >= con.accountValue(i * 2 + 1)))
            ) {
                require(false);
            }
        }
    }
}
