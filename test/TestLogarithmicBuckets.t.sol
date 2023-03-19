// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./mocks/LogarithmicBucketsMock.sol";

contract TestLogarithmicBuckets is LogarithmicBucketsMock, Test {
    using BucketDLLMock for BucketDLL.List;
    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

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
        buckets.update(accounts[0], 3, _head);

        assertEq(buckets.valueOf[accounts[0]], 3);
        assertEq(buckets.getMatch(0), accounts[0]);
        assertEq(buckets.buckets[2].getHead(), accounts[0]);
        assertEq(buckets.buckets[2].getHead(), accounts[0]);
    }

    function testUpdatingFromZeroToZeroShouldRevert(bool _head) public {
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        buckets.update(accounts[0], 0, _head);
    }

    function testShouldNotInsertZeroAddress(bool _head) public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        buckets.update(address(0), 10, _head);
    }

    function testShouldHaveTheRightOrderWithinABucketFIFO() public {
        buckets.update(accounts[0], 16, false);
        buckets.update(accounts[1], 16, false);
        buckets.update(accounts[2], 16, false);

        BucketDLL.List storage list = buckets.buckets[16];
        address head = list.getNext(address(0));
        address next1 = list.getNext(head);
        address next2 = list.getNext(next1);
        assertEq(head, accounts[0]);
        assertEq(next1, accounts[1]);
        assertEq(next2, accounts[2]);
    }

    function testShouldHaveTheRightOrderWithinABucketLIFO() public {
        buckets.update(accounts[0], 16, true);
        buckets.update(accounts[1], 16, true);
        buckets.update(accounts[2], 16, true);

        BucketDLL.List storage list = buckets.buckets[16];
        address head = list.getNext(address(0));
        address next1 = list.getNext(head);
        address next2 = list.getNext(next1);
        assertEq(head, accounts[2]);
        assertEq(next1, accounts[1]);
        assertEq(next2, accounts[0]);
    }

    function testInsertRemoveOneSingleAccount(bool _head1, bool _head2) public {
        buckets.update(accounts[0], 1, _head1);
        buckets.update(accounts[0], 0, _head2);

        assertEq(buckets.valueOf[accounts[0]], 0);
        assertEq(buckets.getMatch(0), address(0));
        assertEq(buckets.buckets[1].getHead(), address(0));
    }

    function testShouldInsertTwoAccounts(bool _head1, bool _head2) public {
        buckets.update(accounts[0], 16, _head1);
        buckets.update(accounts[1], 4, _head2);

        assertEq(buckets.getMatch(16), accounts[0]);
        assertEq(buckets.getMatch(2), accounts[1]);
        assertEq(buckets.buckets[4].getHead(), accounts[1]);
    }

    function testShouldRemoveOneAccountOverTwo() public {
        buckets.update(accounts[0], 4, false);
        buckets.update(accounts[1], 16, false);
        buckets.update(accounts[0], 0, false);

        assertEq(buckets.getMatch(4), accounts[1]);
        assertEq(buckets.valueOf[accounts[0]], 0);
        assertEq(buckets.valueOf[accounts[1]], 16);
        assertEq(buckets.buckets[16].getHead(), accounts[1]);
        assertEq(buckets.buckets[4].getHead(), address(0));
    }

    function testShouldRemoveBothAccounts() public {
        buckets.update(accounts[0], 4, true);
        buckets.update(accounts[1], 4, true);
        buckets.update(accounts[0], 0, true);
        buckets.update(accounts[1], 0, true);

        assertEq(buckets.getMatch(4), address(0));
    }

    function testGetMatch() public {
        assertEq(buckets.getMatch(0), address(0));
        assertEq(buckets.getMatch(1000), address(0));

        buckets.update(accounts[0], 16, false);
        assertEq(buckets.getMatch(1), accounts[0], "head before");
        assertEq(buckets.getMatch(16), accounts[0], "head equal");
        assertEq(buckets.getMatch(32), accounts[0], "head above");
    }
}

contract TestProveLogarithmicBuckets is LogarithmicBucketsMock, Test {
    function isPowerOfTwo(uint256 x) public pure returns (bool) {
        unchecked {
            return x != 0 && (x & (x - 1)) == 0;
        }
    }

    function testProveComputeBucket(uint256 _value) public {
        uint256 bucket = LogarithmicBuckets.highestSetBit(_value);
        unchecked {
            // cross-check that bucket == 2^{floor(log_2 value)}, or 0 if value == 0
            assertTrue(bucket == 0 || isPowerOfTwo(bucket));
            assertTrue(bucket <= _value);
            assertTrue(_value <= 2 * bucket - 1); // abusing overflow when bucket == 2**255
        }
    }

    function testProveNextBucket(uint256 _value) public {
        uint256 curr = LogarithmicBuckets.highestSetBit(_value);
        uint256 next = nextBucketValue(_value);
        uint256 bucketsMask = buckets.bucketsMask;
        // Check that `next` is a power of two or zero.
        assertTrue(next == 0 || isPowerOfTwo(next));
        // Check that `next` is a strictly higher non-empty bucket, or zero.
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

    function testProveHighestBucket() public {
        uint256 highest = highestBucketValue();
        uint256 bucketsMask = buckets.bucketsMask;
        // check that `highest` is a power of two or zero.
        assertTrue(highest == 0 || isPowerOfTwo(highest));
        // check that `highest` is a non-empty bucket or zero.
        assertTrue(highest == 0 || bucketsMask & highest != 0);
        unchecked {
            // check that `highest` is the highest non-empty bucket, if exists.
            // note: this also checks that all the lower buckets are empty when `highest` == 0
            for (uint256 i = 1 >> 256; i > highest; i >>= 1) {
                assertTrue(bucketsMask & i == 0);
            }
        }
    }

    function testProveHighestPrevEquivalence(uint256 _value) public {
        uint256 curr = LogarithmicBuckets.highestSetBit(_value);
        uint256 next = nextBucketValue(_value);

        if (next == 0) {
            uint256 highest = highestBucketValue();
            // check that in this case, `highest` is smaller than `curr`.
            assertTrue(highest <= curr);
        }
    }
}
