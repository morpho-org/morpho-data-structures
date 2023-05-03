// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/LogarithmicBuckets.sol";

contract TestLogarithmicBucketsGas is Test {
    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

    /* STORAGE */

    LogarithmicBuckets.Buckets internal _buckets;

    // Gas accounting.
    uint256 internal _insertCost;
    uint256 internal _insertCount;
    uint256 internal _updateValueCost;
    uint256 internal _updateValueCount;
    uint256 internal _removeCost;
    uint256 internal _removeCount;
    uint256 internal _getMatchCost;
    uint256 internal _getMatchCount;

    /* PUBLIC */

    function testGasUsage() public noGasMetering {
        for (uint256 i; i <= 10000; i++) {
            // Get a random amount.
            uint96 amount = uint96(uint256(keccak256(abi.encode(i))));

            // Reset the free memory pointer.
            assembly {
                mstore(0x40, 0x80)
            }

            // Insert into DS (p=1/2).
            if (amount % 4 < 2) {
                // Measure insert.
                startGasMetering();
                _buckets.update(address(uint160(amount)), amount, true);
                _insertCost += stopGasMetering();
                _insertCount++;
            }
            // Update value in same bucket (p=1/4).
            else if (amount % 4 == 2) {
                // Get an account to update its value.
                address toUpdate = _buckets.getMatch(amount);

                if (toUpdate != address(0)) {
                    // Measure updateValue.
                    startGasMetering();
                    _buckets.update(toUpdate, amount, true);
                    _updateValueCost += stopGasMetering();
                    _updateValueCount++;
                }
            }
            // Remove from DS (p=1/4).
            else {
                // Measure getMatch.
                startGasMetering();
                address toUpdate = _buckets.getMatch(amount);
                _getMatchCost += stopGasMetering();
                _getMatchCount++;

                if (toUpdate != address(0)) {
                    // Measure remove.
                    startGasMetering();
                    _buckets.update(_buckets.getMatch(amount), 0, true);
                    _removeCost += stopGasMetering();
                    _removeCount++;
                }
            }
        }

        // Print average cost of insert, updateValue, remove and getMatch.
        console.log("insert average cost:", _insertCost / _insertCount);
        console.log("update average cost:", _updateValueCost / _updateValueCount);
        console.log("remove average cost:", _removeCost / _removeCount);
        console.log("match average cost: ", _getMatchCost / _getMatchCount);
    }
}
