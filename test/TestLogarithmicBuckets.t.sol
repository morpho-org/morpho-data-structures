// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/LogarithmicBuckets.sol";

contract TestLogarithmicBuckets is Test {
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    uint256 public NDS = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    LogarithmicBuckets.BucketList internal bucketList;

    function setUp() public {
        accounts = new address[](NDS);
        accounts[0] = address(this);
        for (uint256 i = 1; i < NDS; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount() public {
        bucketList.update(accounts[0], 1);

        assertEq(bucketList.getValueOf(accounts[0]), 1);
        assertEq(bucketList.getAccount(0, true), accounts[0]);
        assertEq(bucketList.getMaxBucket(), 1);
        assertEq(bucketList.getBucketOf(accounts[0]), 1);
    }

    function testUpdatingFromZeroToZeroShouldRevert() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        bucketList.update(accounts[0], 0);
    }

    function testShouldNotInsertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        bucketList.update(address(0), 10);
    }

    function testShouldHaveTheRightOrderWithinABucket() public {
        bucketList.update(accounts[0], 16);
        bucketList.update(accounts[1], 16);
        bucketList.update(accounts[2], 16);

        address head = bucketList.getAccount(16, true);
        address next1 = bucketList.getNext(head);
        address next2 = bucketList.getNext(next1);
        assertEq(head, accounts[0]);
        assertEq(next1, accounts[1]);
        assertEq(next2, accounts[2]);
    }

    function testInsertRemoveOneSingleAccount() public {
        bucketList.update(accounts[0], 1);
        bucketList.update(accounts[0], 0);

        assertEq(bucketList.getValueOf(accounts[0]), 0);
        assertEq(bucketList.getAccount(0, true), address(0));
        assertEq(bucketList.getMaxBucket(), 0);
        assertEq(bucketList.getBucketOf(accounts[0]), 0);
    }

    function testShouldInsertTwoAccounts() public {
        bucketList.update(accounts[0], 16);
        bucketList.update(accounts[1], 4);

        assertEq(bucketList.getAccount(16, true), accounts[0]);
        assertEq(bucketList.getAccount(2, true), accounts[1]);
        assertEq(bucketList.getMaxBucket(), 1 << 4);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        bucketList.update(accounts[0], 4);
        bucketList.update(accounts[1], 16);
        bucketList.update(accounts[0], 0);

        assertEq(bucketList.getAccount(4, true), accounts[1]);
        assertEq(bucketList.getValueOf(accounts[0]), 0);
        assertEq(bucketList.getValueOf(accounts[1]), 16);
        assertEq(bucketList.getMaxBucket(), 1 << 4);
    }

    function testShouldRemoveBothAccounts() public {
        bucketList.update(accounts[0], 4);
        bucketList.update(accounts[1], 4);
        bucketList.update(accounts[0], 0);
        bucketList.update(accounts[1], 0);

        assertEq(bucketList.getAccount(4, true), address(0));
    }

    function testGetMaxBucket() public {
        bucketList.update(accounts[0], 1);
        assertEq(bucketList.getMaxBucket(), 1);
        bucketList.update(accounts[1], 2);
        assertEq(bucketList.getMaxBucket(), 1 << 1);
        bucketList.update(accounts[2], 4);
        assertEq(bucketList.getMaxBucket(), 1 << 2);
        bucketList.update(accounts[3], 16);
        assertEq(bucketList.getMaxBucket(), 1 << 4);
        bucketList.update(accounts[3], 0);
        assertEq(bucketList.getMaxBucket(), 1 << 2);
        bucketList.update(accounts[2], 0);
        assertEq(bucketList.getMaxBucket(), 1 << 1);
        bucketList.update(accounts[1], 0);
        assertEq(bucketList.getMaxBucket(), 1);
    }

    function testGetHead() public {
        assertEq(bucketList.getAccount(0, true), address(0));
        assertEq(bucketList.getAccount(1000, true), address(0));

        bucketList.update(accounts[0], 16);
        assertEq(bucketList.getAccount(1, true), accounts[0], "head before");
        assertEq(bucketList.getAccount(16, true), accounts[0], "head equal");
        assertEq(bucketList.getAccount(32, true), accounts[0], "head above");
    }

    function testGetNext() public {
        bucketList.update(accounts[0], 2);
        bucketList.update(accounts[1], 4);
        bucketList.update(accounts[2], 6);
        bucketList.update(accounts[3], 16);

        address out1 = bucketList.getNext(address(0));
        assertEq(out1, accounts[0], "out1");

        address out2 = bucketList.getNext(out1);
        assertEq(out2, accounts[1], "out2");

        address out3 = bucketList.getNext(out2);
        assertEq(out3, accounts[2], "out3");

        address out4 = bucketList.getNext(out3);
        assertEq(out4, accounts[3], "out4");

        address out5 = bucketList.getNext(out4);
        assertEq(out5, address(0), "out5");
    }
}
