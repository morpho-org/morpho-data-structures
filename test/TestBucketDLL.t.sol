// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/BucketDLL.sol";

contract TestDoubleLinkedList is Test {
    using BucketDLL for BucketDLL.List;

    uint256 public NDS = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    BucketDLL.List internal list;

    function setUp() public {
        accounts = new address[](NDS);
        accounts[0] = address(this);
        for (uint256 i = 1; i < NDS; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount() public {
        list.insert(accounts[0]);

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[0]);
        assertEq(list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(list.getNext(accounts[0]), ADDR_ZERO);
    }

    function testShouldHaveTheRightOrder() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[1]);
    }

    function testShouldRemoveOneSingleAccount() public {
        list.insert(accounts[0]);
        list.remove(accounts[0]);

        assertEq(list.getHead(), ADDR_ZERO);
        assertEq(list.getTail(), ADDR_ZERO);
        assertEq(list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(list.getNext(accounts[0]), ADDR_ZERO);
    }

    function testShouldInsertTwoAccounts() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[1]);
        assertEq(list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(list.getNext(accounts[0]), accounts[1]);
        assertEq(list.getPrev(accounts[1]), accounts[0]);
        assertEq(list.getNext(accounts[1]), ADDR_ZERO);
    }

    function testShouldInsertThreeAccounts() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.insert(accounts[2]);

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[2]);
        assertEq(list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(list.getNext(accounts[0]), accounts[1]);
        assertEq(list.getPrev(accounts[1]), accounts[0]);
        assertEq(list.getNext(accounts[1]), accounts[2]);
        assertEq(list.getPrev(accounts[2]), accounts[1]);
        assertEq(list.getNext(accounts[2]), ADDR_ZERO);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.remove(accounts[0]);

        assertEq(list.getHead(), accounts[1]);
        assertEq(list.getTail(), accounts[1]);
        assertEq(list.getPrev(accounts[1]), ADDR_ZERO);
        assertEq(list.getNext(accounts[1]), ADDR_ZERO);
    }

    function testShouldRemoveBothAccounts() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.remove(accounts[0]);
        list.remove(accounts[1]);

        assertEq(list.getHead(), ADDR_ZERO);
        assertEq(list.getTail(), ADDR_ZERO);
    }

    function testShouldInsertThreeAccountsAndRemoveThem() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.insert(accounts[2]);

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[2]);

        // Remove account 0.
        list.remove(accounts[0]);
        assertEq(list.getHead(), accounts[1]);
        assertEq(list.getTail(), accounts[2]);
        assertEq(list.getPrev(accounts[1]), ADDR_ZERO);
        assertEq(list.getNext(accounts[1]), accounts[2]);

        assertEq(list.getPrev(accounts[2]), accounts[1]);
        assertEq(list.getNext(accounts[2]), ADDR_ZERO);

        // Remove account 1.
        list.remove(accounts[1]);
        assertEq(list.getHead(), accounts[2]);
        assertEq(list.getTail(), accounts[2]);
        assertEq(list.getPrev(accounts[2]), ADDR_ZERO);
        assertEq(list.getNext(accounts[2]), ADDR_ZERO);

        // Remove account 2.
        list.remove(accounts[2]);
        assertEq(list.getHead(), ADDR_ZERO);
        assertEq(list.getTail(), ADDR_ZERO);
    }

    function testShouldInsertAccountsInFIFOOrder() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            list.insert(accounts[i]);
        }

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[accounts.length - 1]);

        address nextAccount = accounts[0];
        for (uint256 i = 0; i < accounts.length - 1; i++) {
            nextAccount = list.getNext(nextAccount);
            assertEq(nextAccount, accounts[i + 1]);
        }

        address prevAccount = accounts[accounts.length - 1];
        for (uint256 i = 0; i < accounts.length - 1; i++) {
            prevAccount = list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[accounts.length - i - 2]);
        }
    }

    function testShouldRemoveAllAccounts() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            list.insert(accounts[i]);
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            list.remove(accounts[i]);
        }

        assertEq(list.getHead(), ADDR_ZERO);
        assertEq(list.getTail(), ADDR_ZERO);
    }

}
