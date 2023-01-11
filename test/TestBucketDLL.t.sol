// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/BucketDLL.sol";

contract TestDoubleLinkedList is Test {
    using BucketDLL for BucketDLL.List;

    uint256 internal numberOfAccounts = 50;
    address[] public accounts;

    BucketDLL.List internal list;

    function setUp() public {
        accounts = new address[](numberOfAccounts);
        accounts[0] = address(1);
        for (uint256 i = 1; i < numberOfAccounts; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount(address _account) public {
        vm.assume(_account != address(0));
        
        list.insert(_account);
        assertEq(list.getHead(), _account);
        assertEq(list.getTail(), _account);
        assertEq(list.getPrev(accounts[0]), address(0));
        assertEq(list.getNext(accounts[0]), address(0));
    }

    function testShouldRemoveOneSingleAccount() public {
        list.insert(accounts[0]);
        list.remove(accounts[0]);

        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
        assertEq(list.getPrev(accounts[0]), address(0));
        assertEq(list.getNext(accounts[0]), address(0));
    }

    function testShouldInsertTwoAccounts() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[1]);
        assertEq(list.getPrev(accounts[0]), address(0));
        assertEq(list.getNext(accounts[0]), accounts[1]);
        assertEq(list.getPrev(accounts[1]), accounts[0]);
        assertEq(list.getNext(accounts[1]), address(0));
    }

    function testShouldInsertThreeAccounts() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.insert(accounts[2]);

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[2]);
        assertEq(list.getPrev(accounts[0]), address(0));
        assertEq(list.getNext(accounts[0]), accounts[1]);
        assertEq(list.getPrev(accounts[1]), accounts[0]);
        assertEq(list.getNext(accounts[1]), accounts[2]);
        assertEq(list.getPrev(accounts[2]), accounts[1]);
        assertEq(list.getNext(accounts[2]), address(0));
    }

    function testShouldRemoveOneAccountOverTwo() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.remove(accounts[0]);

        assertEq(list.getHead(), accounts[1]);
        assertEq(list.getTail(), accounts[1]);
        assertEq(list.getPrev(accounts[1]), address(0));
        assertEq(list.getNext(accounts[1]), address(0));
    }

    function testShouldRemoveBothAccounts() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.remove(accounts[0]);
        list.remove(accounts[1]);

        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
    }

    function testShouldInsertThreeAccountsAndRemoveThem() public {
        list.insert(accounts[0]);
        list.insert(accounts[1]);
        list.insert(accounts[2]);

        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[2]);

        // Remove account 1.
        list.remove(accounts[1]);
        assertEq(list.getHead(), accounts[0]);
        assertEq(list.getTail(), accounts[2]);
        assertEq(list.getPrev(accounts[0]), address(0));
        assertEq(list.getNext(accounts[0]), accounts[2]);

        assertEq(list.getPrev(accounts[2]), accounts[0]);
        assertEq(list.getNext(accounts[2]), address(0));

        // Remove account 0.
        list.remove(accounts[0]);
        assertEq(list.getHead(), accounts[2]);
        assertEq(list.getTail(), accounts[2]);
        assertEq(list.getPrev(accounts[2]), address(0));
        assertEq(list.getNext(accounts[2]), address(0));

        // Remove account 2.
        list.remove(accounts[2]);
        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
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
        for (uint256 i = accounts.length - 2; i > 0; i--) {
            prevAccount = list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[i]);
        }
    }

    function testShouldRemoveAllAccounts() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            list.insert(accounts[i]);
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            list.remove(accounts[i]);
        }

        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
    }

}
