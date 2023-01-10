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
        assertEq(bucketList.getMatch(0, true), accounts[0]);
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

        address head = bucketList.getMatch(16, true);
        address next1 = bucketList.getFollowing(head, true);
        address next2 = bucketList.getFollowing(next1, true);
        assertEq(head, accounts[0]);
        assertEq(next1, accounts[1]);
        assertEq(next2, accounts[2]);
    }

    function testInsertRemoveOneSingleAccount() public {
        bucketList.update(accounts[0], 1);
        bucketList.update(accounts[0], 0);

        assertEq(bucketList.getValueOf(accounts[0]), 0);
        assertEq(bucketList.getMatch(0, true), address(0));
        assertEq(bucketList.getMaxBucket(), 0);
        assertEq(bucketList.getBucketOf(accounts[0]), 0);
    }

    function testShouldInsertTwoAccounts() public {
        bucketList.update(accounts[0], 16);
        bucketList.update(accounts[1], 4);

        assertEq(bucketList.getMatch(16, true), accounts[0]);
        assertEq(bucketList.getMatch(2, true), accounts[1]);
        assertEq(bucketList.getMaxBucket(), 1 << 4);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        bucketList.update(accounts[0], 4);
        bucketList.update(accounts[1], 16);
        bucketList.update(accounts[0], 0);

        assertEq(bucketList.getMatch(4, true), accounts[1]);
        assertEq(bucketList.getValueOf(accounts[0]), 0);
        assertEq(bucketList.getValueOf(accounts[1]), 16);
        assertEq(bucketList.getMaxBucket(), 1 << 4);
    }

    function testShouldRemoveBothAccounts() public {
        bucketList.update(accounts[0], 4);
        bucketList.update(accounts[1], 4);
        bucketList.update(accounts[0], 0);
        bucketList.update(accounts[1], 0);

        assertEq(bucketList.getMatch(4, true), address(0));
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
        assertEq(bucketList.getMatch(0, true), address(0));
        assertEq(bucketList.getMatch(1000, true), address(0));

        bucketList.update(accounts[0], 16);
        assertEq(bucketList.getMatch(1, true), accounts[0], "head before");
        assertEq(bucketList.getMatch(16, true), accounts[0], "head equal");
        assertEq(bucketList.getMatch(32, true), accounts[0], "head above");
    }

    function testGetFollowing() public {
        bucketList.update(accounts[0], 2);
        bucketList.update(accounts[1], 4);
        bucketList.update(accounts[2], 6);
        bucketList.update(accounts[3], 16);

        // test get next
        address next1 = bucketList.getFollowing(address(0), true);
        assertEq(next1, accounts[0], "next1");

        address next2 = bucketList.getFollowing(next1, true);
        assertEq(next2, accounts[1], "next2");

        address next3 = bucketList.getFollowing(next2, true);
        assertEq(next3, accounts[2], "next3");

        address next4 = bucketList.getFollowing(next3, true);
        assertEq(next4, accounts[3], "next4");

        address next5 = bucketList.getFollowing(next4, true);
        assertEq(next5, address(0), "next5");

        // test get prev
        address prev1 = bucketList.getFollowing(address(0), false);
        assertEq(prev1, accounts[3], "prev1");

        address prev2 = bucketList.getFollowing(prev1, false);
        assertEq(prev2, accounts[2], "prev2");

        address prev3 = bucketList.getFollowing(prev2, false);
        assertEq(prev3, accounts[1], "prev3");

        address prev4 = bucketList.getFollowing(prev3, false);
        assertEq(prev4, accounts[0], "prev4");

        address prev5 = bucketList.getFollowing(prev4, false);
        assertEq(prev5, address(0), "prev5");
    }
}
