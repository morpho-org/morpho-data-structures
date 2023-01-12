// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./mocks/LogarithmicBucketsMock.sol";

contract TestLogarithmicBuckets is LogarithmicBucketsMock, Test {
    using BucketDLL for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    uint256 public NDS = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    function setUp() public {
        accounts = new address[](NDS);
        accounts[0] = address(bytes20(keccak256("TestLogarithmicBuckets.accounts")));
        for (uint256 i = 1; i < NDS; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testEmpty(uint256 _value, bool _fifo) public {
        assertEq(bucketList.getMatch(_value, _fifo), address(0));
    }

    function testInsertOneSingleAccount(bool _fifo) public {
        bucketList.update(accounts[0], 3, _fifo);

        assertEq(bucketList.getValueOf(accounts[0]), 3);
        assertEq(bucketList.getMatch(0), accounts[0]);
        assertEq(bucketList.getBucketOf(3).getHead(), accounts[0]);
        assertEq(bucketList.getBucketOf(2).getHead(), accounts[0]);
    }

    function testUpdatingFromZeroToZeroShouldRevert(bool _lifo) public {
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        bucketList.update(accounts[0], 0, _lifo);
    }

    function testShouldNotInsertZeroAddress(bool _lifo) public {
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        bucketList.update(address(0), 10, _lifo);
    }

    function testShouldHaveTheRightOrderWithinABucketFIFO() public {
        bucketList.update(accounts[0], 16, false);
        bucketList.update(accounts[1], 16, false);
        bucketList.update(accounts[2], 16, false);

        BucketDLL.List storage list = bucketList.getBucketOf(16);
        address head = list.getNext(address(0));
        address next1 = list.getNext(head);
        address next2 = list.getNext(next1);
        assertEq(head, accounts[0]);
        assertEq(next1, accounts[1]);
        assertEq(next2, accounts[2]);
    }

    function testShouldHaveTheRightOrderWithinABucketLIFO() public {
        bucketList.update(accounts[0], 16, true);
        bucketList.update(accounts[1], 16, true);
        bucketList.update(accounts[2], 16, true);

        BucketDLL.List storage list = bucketList.getBucketOf(16);
        address head = list.getNext(address(0));
        address next1 = list.getNext(head);
        address next2 = list.getNext(next1);
        assertEq(head, accounts[2]);
        assertEq(next1, accounts[1]);
        assertEq(next2, accounts[0]);
    }

    function testInsertRemoveOneSingleAccount(bool _lifo1, bool _lifo2) public {
        bucketList.update(accounts[0], 1, _lifo1);
        bucketList.update(accounts[0], 0, _lifo2);

        assertEq(bucketList.getValueOf(accounts[0]), 0);
        assertEq(bucketList.getMatch(0), address(0));
        assertEq(bucketList.getBucketOf(1).getHead(), address(0));
    }

    function testShouldInsertTwoAccounts(bool _lifo1, bool _lifo2) public {
        bucketList.update(accounts[0], 16, _lifo1);
        bucketList.update(accounts[1], 4, _lifo2);

        assertEq(bucketList.getMatch(16), accounts[0]);
        assertEq(bucketList.getMatch(2), accounts[1]);
        assertEq(bucketList.getBucketOf(4).getHead(), accounts[1]);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        bucketList.update(accounts[0], 4, false);
        bucketList.update(accounts[1], 16, false);
        bucketList.update(accounts[0], 0, false);

        assertEq(bucketList.getMatch(4), accounts[1]);
        assertEq(bucketList.getValueOf(accounts[0]), 0);
        assertEq(bucketList.getValueOf(accounts[1]), 16);
        assertEq(bucketList.getBucketOf(16).getHead(), accounts[1]);
        assertEq(bucketList.getBucketOf(4).getHead(), address(0));
    }

    function testShouldRemoveBothAccounts() public {
        bucketList.update(accounts[0], 4, true);
        bucketList.update(accounts[1], 4, true);
        bucketList.update(accounts[0], 0, true);
        bucketList.update(accounts[1], 0, true);

        assertEq(bucketList.getMatch(4), address(0));
    }

    function testGetMatch() public {
        assertEq(bucketList.getMatch(0), address(0));
        assertEq(bucketList.getMatch(1000), address(0));

        bucketList.update(accounts[0], 16, false);
        assertEq(bucketList.getMatch(1), accounts[0], "head before");
        assertEq(bucketList.getMatch(16), accounts[0], "head equal");
        assertEq(bucketList.getMatch(32), accounts[0], "head above");
    }
}
