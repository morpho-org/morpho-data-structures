// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/LogarithmicBuckets.sol";

contract TestLogBuckets is Test {
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    uint256 public NDS = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    LogarithmicBuckets.BucketList internal bucketlist;

    function setUp() public {
        accounts = new address[](NDS);
        accounts[0] = address(this);
        for (uint256 i = 1; i < NDS; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount() public {
        bucketlist.update(accounts[0], 1);

        assertEq(bucketlist.getValueOf(accounts[0]), 1);
        assertEq(bucketlist.getHead(0), accounts[0]);
        assertEq(bucketlist.getMaxIndex(), 0);
        assertEq(bucketlist.getBucketOf(accounts[0]), 0);
    }

    function testUpdatingFromZeroToZeroShouldNotInsert() public {
        bucketlist.update(accounts[0], 0);
        assertEq(bucketlist.getHead(0), address(0));
    }

    function testShouldNotInsertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        bucketlist.update(address(0), 10);
    }

    function testShouldHaveTheRightOrderWithinABucket() public {
        bucketlist.update(accounts[0], 16);
        bucketlist.update(accounts[1], 16);
        bucketlist.update(accounts[2], 16);

        address head = bucketlist.getHead(16);
        address next1 = bucketlist.getNext(head);
        address next2 = bucketlist.getNext(next1);
        assertEq(head, accounts[0]);
        assertEq(next1, accounts[1]);
        assertEq(next2, accounts[2]);
    }

    function testInsertRemoveOneSingleAccount() public {
        bucketlist.update(accounts[0], 1);
        bucketlist.update(accounts[0], 0);

        assertEq(bucketlist.getValueOf(accounts[0]), 0);
        assertEq(bucketlist.getHead(0), address(0));
        assertEq(bucketlist.getMaxIndex(), 0);
        assertEq(bucketlist.getBucketOf(accounts[0]), 0);
    }

    function testShouldInsertTwoAccounts() public {
        bucketlist.update(accounts[0], 16);
        bucketlist.update(accounts[1], 4);

        assertEq(bucketlist.getHead(16), accounts[0]);
        assertEq(bucketlist.getHead(4), accounts[1]);
        assertEq(bucketlist.getMaxIndex(), 2);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        bucketlist.update(accounts[0], 4);
        bucketlist.update(accounts[1], 16);
        bucketlist.update(accounts[0], 0);

        assertEq(bucketlist.getHead(4), accounts[1]);
        assertEq(bucketlist.getValueOf(accounts[0]), 0);
        assertEq(bucketlist.getValueOf(accounts[1]), 16);
        assertEq(bucketlist.getMaxIndex(), 2);
    }

    function testShouldRemoveBothAccounts() public {
        bucketlist.update(accounts[0], 4);
        bucketlist.update(accounts[1], 4);
        bucketlist.update(accounts[0], 0);
        bucketlist.update(accounts[1], 0);

        assertEq(bucketlist.getHead(4), address(0));
    }

    function testGetMaxIndex() public {
        bucketlist.update(accounts[0], 1);
        assertEq(bucketlist.getMaxIndex(), 0);
        bucketlist.update(accounts[1], 2);
        assertEq(bucketlist.getMaxIndex(), 0);
        bucketlist.update(accounts[2], 4);
        assertEq(bucketlist.getMaxIndex(), 1);
        bucketlist.update(accounts[3], 16);
        assertEq(bucketlist.getMaxIndex(), 2);
        bucketlist.update(accounts[3], 0);
        assertEq(bucketlist.getMaxIndex(), 1);
        bucketlist.update(accounts[2], 0);
        assertEq(bucketlist.getMaxIndex(), 0);
        bucketlist.update(accounts[1], 0);
        assertEq(bucketlist.getMaxIndex(), 0);
    }

    function testGetHead() public {
        assertEq(bucketlist.getHead(0), address(0));
        assertEq(bucketlist.getHead(1000), address(0));

        bucketlist.update(accounts[0], 16);
        assertEq(bucketlist.getHead(1), accounts[0]);
        assertEq(bucketlist.getHead(16), accounts[0]);
        assertEq(bucketlist.getHead(32), accounts[0]);
    }
}
