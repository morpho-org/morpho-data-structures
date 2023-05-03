// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./mocks/BucketDLLMock.sol";

contract TestBucketDLL is Test {
    using BucketDLLMock for BucketDLL.List;

    /* STORAGE */

    uint256 internal _numberOfAccounts = 50;
    address[] public accounts;

    BucketDLL.List internal _list;

    /* PUBLIC */

    function setUp() public {
        accounts = new address[](_numberOfAccounts);
        accounts[0] = address(bytes20(keccak256("TestBucketDLL.accounts")));
        for (uint256 i = 1; i < _numberOfAccounts; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount(address account, bool head) public {
        vm.assume(account != address(0));

        _list.insert(account, head);
        assertEq(_list.getHead(), account);
        assertEq(_list.getTail(), account);
        assertEq(_list.getPrev(account), address(0));
        assertEq(_list.getNext(account), address(0));
    }

    function testShouldRemoveOneSingleAccount(address account) public {
        vm.assume(account != address(0));

        _list.insert(account, false);
        _list.remove(account);

        assertEq(_list.getHead(), address(0));
        assertEq(_list.getTail(), address(0));
        assertEq(_list.getPrev(account), address(0));
        assertEq(_list.getNext(account), address(0));
    }

    function testShouldInsertTwoAccounts(address account0, address account1, bool head) public {
        vm.assume(account0 != address(0) && account1 != address(0));
        vm.assume(account0 != account1);

        _list.insert(account0, false);
        _list.insert(account1, head);

        if (head) {
            assertEq(_list.getHead(), account1);
            assertEq(_list.getTail(), account0);
            assertEq(_list.getPrev(account1), address(0));
            assertEq(_list.getNext(account1), account0);
            assertEq(_list.getPrev(account0), account1);
            assertEq(_list.getNext(account0), address(0));
        } else {
            assertEq(_list.getHead(), account0);
            assertEq(_list.getTail(), account1);
            assertEq(_list.getPrev(account0), address(0));
            assertEq(_list.getNext(account0), account1);
            assertEq(_list.getPrev(account1), account0);
            assertEq(_list.getNext(account1), address(0));
        }
    }

    function testShouldInsertAccountsInFIFOOrder() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            _list.insert(accounts[i], false);
        }

        assertEq(_list.getHead(), accounts[0]);
        assertEq(_list.getTail(), accounts[accounts.length - 1]);

        address nextAccount = accounts[0];
        for (uint256 i = 0; i < accounts.length - 1; i++) {
            nextAccount = _list.getNext(nextAccount);
            assertEq(nextAccount, accounts[i + 1]);
        }

        address prevAccount = accounts[accounts.length - 1];
        for (uint256 i = accounts.length - 2; i > 0; i--) {
            prevAccount = _list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[i]);
        }
    }

    function testShouldInsertAccountsInLIFOOrder() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            _list.insert(accounts[i], true);
        }

        assertEq(_list.getHead(), accounts[accounts.length - 1]);
        assertEq(_list.getTail(), accounts[0]);

        address nextAccount = accounts[accounts.length - 1];
        for (uint256 i = accounts.length - 1; i > 0; i--) {
            nextAccount = _list.getNext(nextAccount);
            assertEq(nextAccount, accounts[i - 1]);
        }

        address prevAccount = accounts[0];
        for (uint256 i = 0; i < accounts.length - 1; i++) {
            prevAccount = _list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[i + 1]);
        }
    }

    function testShouldRemoveOneAccountOverTwo(address account0, address account1) public {
        vm.assume(account0 != address(0) && account1 != address(0));
        vm.assume(account0 != account1);

        _list.insert(account0, false);
        _list.insert(account1, false);
        _list.remove(account0);

        assertEq(_list.getHead(), account1);
        assertEq(_list.getTail(), account1);
        assertEq(_list.getPrev(account0), address(0));
        assertEq(_list.getNext(account0), address(0));
        assertEq(_list.getPrev(account1), address(0));
        assertEq(_list.getNext(account1), address(0));
    }

    function testShouldRemoveBothAccounts(address account0, address account1, bool head1, bool head2) public {
        vm.assume(account0 != address(0) && account1 != address(0));
        vm.assume(account0 != account1);

        _list.insert(account0, head1);
        _list.insert(account1, head2);
        _list.remove(account0);
        _list.remove(account1);

        assertEq(_list.getHead(), address(0));
        assertEq(_list.getTail(), address(0));
    }

    function testShouldInsertThreeAccountsAndRemoveThem(address account0, address account1, address account2) public {
        vm.assume(account0 != address(0) && account1 != address(0) && account2 != address(0));
        vm.assume(account0 != account1 && account1 != account2 && account2 != account0);

        _list.insert(account0, false);
        _list.insert(account1, false);
        _list.insert(account2, false);

        assertEq(_list.getHead(), account0);
        assertEq(_list.getTail(), account2);

        // Remove account 1.
        _list.remove(account1);
        assertEq(_list.getHead(), account0);
        assertEq(_list.getTail(), account2);
        assertEq(_list.getPrev(account0), address(0));
        assertEq(_list.getNext(account0), account2);

        assertEq(_list.getPrev(account2), account0);
        assertEq(_list.getNext(account2), address(0));

        // Remove account 0.
        _list.remove(account0);
        assertEq(_list.getHead(), account2);
        assertEq(_list.getTail(), account2);
        assertEq(_list.getPrev(account2), address(0));
        assertEq(_list.getNext(account2), address(0));

        // Remove account 2.
        _list.remove(account2);
        assertEq(_list.getHead(), address(0));
        assertEq(_list.getTail(), address(0));
    }

    function testShouldRemoveAllAccounts() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            _list.insert(accounts[i], false);
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            _list.remove(accounts[i]);
        }

        assertEq(_list.getHead(), address(0));
        assertEq(_list.getTail(), address(0));
    }
}
