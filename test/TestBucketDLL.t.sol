// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./mocks/BucketDLLMock.sol";

contract TestBucketDLL is Test {
    using BucketDLLMock for BucketDLL.List;

    uint256 internal numberOfAccounts = 50;
    address[] public accounts;

    BucketDLL.List internal list;

    function setUp() public {
        accounts = new address[](numberOfAccounts);
        accounts[0] = address(bytes20(keccak256("TestBucketDLL.accounts")));
        for (uint256 i = 1; i < numberOfAccounts; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount(address account, bool head) public {
        vm.assume(account != address(0));

        list.insert(account, head);
        assertEq(list.getHead(), account);
        assertEq(list.getTail(), account);
        assertEq(list.getPrev(account), address(0));
        assertEq(list.getNext(account), address(0));
    }

    function testShouldRemoveOneSingleAccount(address account) public {
        vm.assume(account != address(0));

        list.insert(account, false);
        list.remove(account);

        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
        assertEq(list.getPrev(account), address(0));
        assertEq(list.getNext(account), address(0));
    }

    function testShouldInsertTwoAccounts(address account0, address account1, bool head) public {
        vm.assume(account0 != address(0) && account1 != address(0));
        vm.assume(account0 != account1);

        list.insert(account0, false);
        list.insert(account1, head);

        if (head) {
            assertEq(list.getHead(), account1);
            assertEq(list.getTail(), account0);
            assertEq(list.getPrev(account1), address(0));
            assertEq(list.getNext(account1), account0);
            assertEq(list.getPrev(account0), account1);
            assertEq(list.getNext(account0), address(0));
        } else {
            assertEq(list.getHead(), account0);
            assertEq(list.getTail(), account1);
            assertEq(list.getPrev(account0), address(0));
            assertEq(list.getNext(account0), account1);
            assertEq(list.getPrev(account1), account0);
            assertEq(list.getNext(account1), address(0));
        }
    }

    function testShouldInsertAccountsInFIFOOrder() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            list.insert(accounts[i], false);
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

    function testShouldInsertAccountsInLIFOOrder() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            list.insert(accounts[i], true);
        }

        assertEq(list.getHead(), accounts[accounts.length - 1]);
        assertEq(list.getTail(), accounts[0]);

        address nextAccount = accounts[accounts.length - 1];
        for (uint256 i = accounts.length - 1; i > 0; i--) {
            nextAccount = list.getNext(nextAccount);
            assertEq(nextAccount, accounts[i - 1]);
        }

        address prevAccount = accounts[0];
        for (uint256 i = 0; i < accounts.length - 1; i++) {
            prevAccount = list.getPrev(prevAccount);
            assertEq(prevAccount, accounts[i + 1]);
        }
    }

    function testShouldRemoveOneAccountOverTwo(address account0, address account1) public {
        vm.assume(account0 != address(0) && account1 != address(0));
        vm.assume(account0 != account1);

        list.insert(account0, false);
        list.insert(account1, false);
        list.remove(account0);

        assertEq(list.getHead(), account1);
        assertEq(list.getTail(), account1);
        assertEq(list.getPrev(account0), address(0));
        assertEq(list.getNext(account0), address(0));
        assertEq(list.getPrev(account1), address(0));
        assertEq(list.getNext(account1), address(0));
    }

    function testShouldRemoveBothAccounts(address account0, address account1, bool head1, bool head2) public {
        vm.assume(account0 != address(0) && account1 != address(0));
        vm.assume(account0 != account1);

        list.insert(account0, head1);
        list.insert(account1, head2);
        list.remove(account0);
        list.remove(account1);

        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
    }

    function testShouldInsertThreeAccountsAndRemoveThem(address account0, address account1, address account2) public {
        vm.assume(account0 != address(0) && account1 != address(0) && account2 != address(0));
        vm.assume(account0 != account1 && account1 != account2 && account2 != account0);

        list.insert(account0, false);
        list.insert(account1, false);
        list.insert(account2, false);

        assertEq(list.getHead(), account0);
        assertEq(list.getTail(), account2);

        // Remove account 1.
        list.remove(account1);
        assertEq(list.getHead(), account0);
        assertEq(list.getTail(), account2);
        assertEq(list.getPrev(account0), address(0));
        assertEq(list.getNext(account0), account2);

        assertEq(list.getPrev(account2), account0);
        assertEq(list.getNext(account2), address(0));

        // Remove account 0.
        list.remove(account0);
        assertEq(list.getHead(), account2);
        assertEq(list.getTail(), account2);
        assertEq(list.getPrev(account2), address(0));
        assertEq(list.getNext(account2), address(0));

        // Remove account 2.
        list.remove(account2);
        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
    }

    function testShouldRemoveAllAccounts() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            list.insert(accounts[i], false);
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            list.remove(accounts[i]);
        }

        assertEq(list.getHead(), address(0));
        assertEq(list.getTail(), address(0));
    }
}
