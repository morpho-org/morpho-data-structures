// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DoubleLinkedList} from "src/DoubleLinkedList.sol";

contract TestDoubleLinkedList is Test {
    using DoubleLinkedList for DoubleLinkedList.List;

    /* STORAGE */

    DoubleLinkedList.List internal _list;

    uint256 public NDS = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    /* PUBLIC */

    function setUp() public {
        accounts = new address[](NDS);
        accounts[0] = address(bytes20(keccak256("TestDoubleLinkedList.accounts")));
        for (uint256 i = 1; i < NDS; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount() public {
        _list.insertSorted(accounts[0], 1, NDS);

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[0]);
        assertEq(_list.getValueOf(accounts[0]), 1);
        assertEq(_list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(_list.getNext(accounts[0]), ADDR_ZERO);
    }

    function testShouldNotInsertAccountWithZeroValue() public {
        vm.expectRevert(abi.encodeWithSignature("ValueIsZero()"));
        _list.insertSorted(accounts[0], 0, NDS);
    }

    function testShouldNotInsertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        _list.insertSorted(address(0), 10, NDS);
    }

    function testShouldNotRemoveAccountThatDoesNotExist() public {
        vm.expectRevert(abi.encodeWithSignature("AccountDoesNotExist()"));
        _list.remove(accounts[0]);
    }

    function testShouldInsertSeveralTimesTheSameAccount() public {
        _list.insertSorted(accounts[0], 1, NDS);
        vm.expectRevert(abi.encodeWithSignature("AccountAlreadyInserted()"));
        _list.insertSorted(accounts[0], 2, NDS);
    }

    function testShouldHaveTheRightOrder() public {
        _list.insertSorted(accounts[0], 20, NDS);
        _list.insertSorted(accounts[1], 40, NDS);
        assertEq(_list.getHead(), accounts[1]);
        assertEq(_list.getTail(), accounts[0]);
    }

    function testShouldRemoveOneSingleAccount() public {
        _list.insertSorted(accounts[0], 1, NDS);
        _list.remove(accounts[0]);

        assertEq(_list.getHead(), ADDR_ZERO);
        assertEq(_list.getTail(), ADDR_ZERO);
        assertEq(_list.getValueOf(accounts[0]), 0);
        assertEq(_list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(_list.getNext(accounts[0]), ADDR_ZERO);
    }

    function testShouldInsertTwoAccounts() public {
        _list.insertSorted(accounts[0], 2, NDS);
        _list.insertSorted(accounts[1], 1, NDS);

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[1]);
        assertEq(_list.getValueOf(accounts[0]), 2);
        assertEq(_list.getValueOf(accounts[1]), 1);
        assertEq(_list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(_list.getNext(accounts[0]), accounts[1]);
        assertEq(_list.getPrev(accounts[1]), accounts[0]);
        assertEq(_list.getNext(accounts[1]), ADDR_ZERO);
    }

    function testShouldInsertThreeAccounts() public {
        _list.insertSorted(accounts[0], 3, NDS);
        _list.insertSorted(accounts[1], 2, NDS);
        _list.insertSorted(accounts[2], 1, NDS);

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[2]);
        assertEq(_list.getValueOf(accounts[0]), 3);
        assertEq(_list.getValueOf(accounts[1]), 2);
        assertEq(_list.getValueOf(accounts[2]), 1);
        assertEq(_list.getPrev(accounts[0]), ADDR_ZERO);
        assertEq(_list.getNext(accounts[0]), accounts[1]);
        assertEq(_list.getPrev(accounts[1]), accounts[0]);
        assertEq(_list.getNext(accounts[1]), accounts[2]);
        assertEq(_list.getPrev(accounts[2]), accounts[1]);
        assertEq(_list.getNext(accounts[2]), ADDR_ZERO);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        _list.insertSorted(accounts[0], 2, NDS);
        _list.insertSorted(accounts[1], 1, NDS);
        _list.remove(accounts[0]);

        assertEq(_list.getHead(), accounts[1]);
        assertEq(_list.getTail(), accounts[1]);
        assertEq(_list.getValueOf(accounts[0]), 0);
        assertEq(_list.getValueOf(accounts[1]), 1);
        assertEq(_list.getPrev(accounts[1]), ADDR_ZERO);
        assertEq(_list.getNext(accounts[1]), ADDR_ZERO);
    }

    function testShouldRemoveBothAccounts() public {
        _list.insertSorted(accounts[0], 2, NDS);
        _list.insertSorted(accounts[1], 1, NDS);
        _list.remove(accounts[0]);
        _list.remove(accounts[1]);

        assertEq(_list.getHead(), ADDR_ZERO);
        assertEq(_list.getTail(), ADDR_ZERO);
    }

    function testShouldInsertThreeAccountsAndRemoveThem() public {
        _list.insertSorted(accounts[0], 3, NDS);
        _list.insertSorted(accounts[1], 2, NDS);
        _list.insertSorted(accounts[2], 1, NDS);

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[2]);

        // Remove account 0.
        _list.remove(accounts[0]);
        assertEq(_list.getHead(), accounts[1]);
        assertEq(_list.getTail(), accounts[2]);
        assertEq(_list.getPrev(accounts[1]), ADDR_ZERO);
        assertEq(_list.getNext(accounts[1]), accounts[2]);

        assertEq(_list.getPrev(accounts[2]), accounts[1]);
        assertEq(_list.getNext(accounts[2]), ADDR_ZERO);

        // Remove account 1.
        _list.remove(accounts[1]);
        assertEq(_list.getHead(), accounts[2]);
        assertEq(_list.getTail(), accounts[2]);
        assertEq(_list.getPrev(accounts[2]), ADDR_ZERO);
        assertEq(_list.getNext(accounts[2]), ADDR_ZERO);

        // Remove account 2.
        _list.remove(accounts[2]);
        assertEq(_list.getHead(), ADDR_ZERO);
        assertEq(_list.getTail(), ADDR_ZERO);
    }

    function testShouldInsertAccountsAllSorted() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            _list.insertSorted(accounts[i], NDS - i, NDS);
        }

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[accounts.length - 1]);

        address nextAccount = accounts[0];
        for (uint256 i = 0; i < accounts.length - 1; i++) {
            nextAccount = _list.getNext(nextAccount);
            assertEq(nextAccount, accounts[i + 1]);
        }

        address prevAccount = accounts[accounts.length - 1];
        for (uint256 i = 0; i < accounts.length - 1; i++) {
            prevAccount = _list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[accounts.length - i - 2]);
        }
    }

    function testShouldRemoveAllSortedAccount() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            _list.insertSorted(accounts[i], NDS - i, NDS);
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            _list.remove(accounts[i]);
        }

        assertEq(_list.getHead(), ADDR_ZERO);
        assertEq(_list.getTail(), ADDR_ZERO);
    }

    function testShouldInsertAccountSortedAtTheBeginningUntilNDS() public {
        uint256 value = 50;
        uint256 newNDS = 10;

        // Add first 10 accounts with decreasing value.
        for (uint256 i = 0; i < 10; i++) {
            _list.insertSorted(accounts[i], value - i, newNDS);
        }

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[9]);

        address nextAccount = accounts[0];
        for (uint256 i = 0; i < 9; i++) {
            nextAccount = _list.getNext(nextAccount);
            assertEq(nextAccount, accounts[i + 1]);
        }

        address prevAccount = accounts[9];
        for (uint256 i = 0; i < 9; i++) {
            prevAccount = _list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[10 - i - 2]);
        }

        // Add last 10 accounts at the same value.
        for (uint256 i = accounts.length - 10; i < NDS; i++) {
            _list.insertSorted(accounts[i], 10, newNDS);
        }

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[accounts.length - 1]);

        nextAccount = accounts[0];
        for (uint256 i = 0; i < 9; i++) {
            nextAccount = _list.getNext(nextAccount);
            assertEq(nextAccount, accounts[i + 1]);
        }

        prevAccount = accounts[9];
        for (uint256 i = 0; i < 9; i++) {
            prevAccount = _list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[10 - i - 2]);
        }
    }
}
