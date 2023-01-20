// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./mocks/LogarithmicBucketsMock.sol";

contract TestLogarithmicBuckets is LogarithmicBucketsMock, Test {
    using BucketDLL for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.BucketList;

    uint256 public accountsLength = 50;
    address[] public accounts;
    address public ADDR_ZERO = address(0);

    function setUp() public {
        accounts = new address[](accountsLength);
        accounts[0] = address(bytes20(keccak256("TestLogarithmicBuckets.accounts")));
        for (uint256 i = 1; i < accountsLength; i++) {
            accounts[i] = address(uint160(accounts[i - 1]) + 1);
        }
    }

    function testInsertOneSingleAccount(bool _head) public {
        bucketList.update(accounts[0], 3, _head);

        assertEq(bucketList.getValueOf(accounts[0]), 3);
        assertEq(bucketList.getMatch(0), accounts[0]);
        assertEq(bucketList.getBucketOf(3).getHead(), accounts[0]);
        assertEq(bucketList.getBucketOf(2).getHead(), accounts[0]);
    }

    function testUpdatingFromZeroToZeroShouldRevert(bool _head) public {
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        bucketList.update(accounts[0], 0, _head);
    }

    function testShouldNotInsertZeroAddress(bool _head) public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        bucketList.update(address(0), 10, _head);
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

    function testInsertRemoveOneSingleAccount(bool _head1, bool _head2) public {
        bucketList.update(accounts[0], 1, _head1);
        bucketList.update(accounts[0], 0, _head2);

        assertEq(bucketList.getValueOf(accounts[0]), 0);
        assertEq(bucketList.getMatch(0), address(0));
        assertEq(bucketList.getBucketOf(1).getHead(), address(0));
    }

    function testShouldInsertTwoAccounts(bool _head1, bool _head2) public {
        bucketList.update(accounts[0], 16, _head1);
        bucketList.update(accounts[1], 4, _head2);

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

    function isPowerOfTwo(uint256 x) public pure returns (bool) {
        unchecked {
            return x != 0 && (x & (x - 1)) == 0;
        }
    }

    function testProveComputeBucket(uint256 _value) public {
        uint256 bucket = LogarithmicBuckets._computeBucket(_value);
        unchecked {
            // cross-check that bucket == 2^{floor(log_2 value)}, or 0 if value == 0
            assertTrue(bucket == 0 || isPowerOfTwo(bucket));
            assertTrue(bucket <= _value);
            assertTrue(_value <= 2 * bucket - 1); // abusing overflow when bucket == 2**255
        }
    }

    function testProveNextBucket(uint256 _value) public {
        uint256 curr = LogarithmicBuckets._computeBucket(_value);
        uint256 next = nextBucket(_value);
        uint256 bucketsMask = bucketList.bucketsMask;
        // check that `next` is a strictly higer non-empty bucket, or zero
        assertTrue(next == 0 || isPowerOfTwo(next));
        assertTrue(next == 0 || next > curr);
        assertTrue(next == 0 || bucketsMask & next != 0);
        unchecked {
            // check that `next` is the lowest one among such higher non-empty buckets, if exist
            // note: this also checks that all the higher buckets are empty when `next` == 0
            for (uint256 i = curr << 1; i != next; i <<= 1) {
                assertTrue(bucketsMask & i == 0);
            }
        }
    }

    function testProvePrevBucket(uint256 _value) public {
        uint256 curr = LogarithmicBuckets._computeBucket(_value);
        uint256 prev = prevBucket(_value);
        uint256 bucketsMask = bucketList.bucketsMask;
        // check that `prev` is a non-empty bucket that is lower than or equal to `curr`; or zero
        assertTrue(prev == 0 || isPowerOfTwo(prev));
        assertTrue(prev <= curr);
        assertTrue(prev == 0 || bucketsMask & prev != 0);
        unchecked {
            // check that `prev` is the highest one among such lower non-empty buckets, if exist
            // note: this also checks that all the lower buckets are empty when `prev` == 0
            for (uint256 i = curr; i > prev; i >>= 1) {
                assertTrue(bucketsMask & i == 0);
            }
        }
    }
}
